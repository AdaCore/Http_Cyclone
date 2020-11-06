------------------------------------------------------------------------------
--                              HTTP_Cyclone                                --
--                                                                          --
--                        Copyright (C) 2020, AdaCore                       --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General  Public  License  distributed  with  this  software;   see  file --
-- LICENSE  If not, go to http://www.gnu.org/licenses for a complete copy   --
-- of the license.                                                          --
------------------------------------------------------------------------------

with Common_Type;  use Common_Type;
with Interfaces.C; use Interfaces.C;
with Ip;           use Ip;
with Net_Mem;      use Net_Mem;
with System;       use System;

package Tcp_Type with SPARK_Mode is

   type Syn_Queue_Size_Max is range 1 .. Natural'Last
   with Size => unsigned'Size;

   -- Maximum SYN queue size for listening sockets
#if TCP_MAX_SYN_QUEUE_SIZE'Defined then
   TCP_MAX_SYN_QUEUE_SIZE : constant Syn_Queue_Size_Max := $TCP_MAX_SYN_QUEUE_SIZE;
#else
   TCP_MAX_SYN_QUEUE_SIZE : constant Syn_Queue_Size_Max := 16;
#end if;

   type Syn_Queue_Size is range 1 .. TCP_MAX_SYN_QUEUE_SIZE
   with Size => unsigned'Size;

   -- Default SYN queue size for listening sockets
#if TCP_DEFAULT_SYN_QUEUE_SIZE'Defined then
   TCP_DEFAULT_SYN_QUEUE_SIZE : constant Syn_Queue_Size := $TCP_DEFAULT_SYN_QUEUE_SIZE;
#else
   TCP_DEFAULT_SYN_QUEUE_SIZE : constant Syn_Queue_Size := 4;
#end if;

   subtype Buffer_Size is Natural range 536 .. Natural'Last;

   -- Maximum acceptable size for the receive buffer
#if TCP_MAX_RX_BUFFER_SIZE'Defined then
   TCP_MAX_RX_BUFFER_SIZE : constant Buffer_Size := $TCP_MAX_RX_BUFFER_SIZE;
#else
   TCP_MAX_RX_BUFFER_SIZE : constant Buffer_Size := 22_880;
#end if;

   -- Maximum acceptable size for the send buffer
#if TCP_MAX_TX_BUFFER_SIZE'Defined then
   TCP_MAX_TX_BUFFER_SIZE : constant Buffer_Size := $TCP_MAX_TX_BUFFER_SIZE;
#else
   TCP_MAX_TX_BUFFER_SIZE : constant Buffer_Size := 22_880;
#end if;

   type Tx_Buffer_Size is range 1 .. TCP_MAX_TX_BUFFER_SIZE;
   type Rx_Buffer_Size is range 1 .. TCP_MAX_RX_BUFFER_SIZE;

   -- Default buffer size for reception
#if TCP_DEFAULT_RX_BUFFER_SIZE'Defined then
   TCP_DEFAULT_RX_BUFFER_SIZE : constant Rx_Buffer_Size := $TCP_DEFAULT_RX_BUFFER_SIZE;
#else
   TCP_DEFAULT_RX_BUFFER_SIZE : constant Rx_Buffer_Size := 2_860;
#end if;

   -- Default buffer size for transmission
#if TCP_DEFAULT_TX_BUFFER_SIZE'Defined then
   TCP_DEFAULT_TX_BUFFER_SIZE : constant Tx_Buffer_Size := $TCP_DEFAULT_TX_BUFFER_SIZE;
#else
   TCP_DEFAULT_TX_BUFFER_SIZE : constant Tx_Buffer_Size := 2_860;
#end if;

   type Mss_Lower_Bound is range 1 .. unsigned_short'Last;
   type Mss_Upper_Bound is range 536 .. unsigned_short'Last;

   -- Mimimum acceptable segment size
#if TCP_MIN_MSS'Defined then
   TCP_MIN_MSS : constant Mss_Lower_Bound := $TCP_MIN_MSS;
#else
   TCP_MIN_MSS : constant Mss_Lower_Bound := 64;
#end if;

   -- Maximum segment size
#if TCP_MAX_MSS'Defined then
   TCP_MAX_MSS : constant Mss_Upper_Bound := $TCP_MAX_MSS;
#else
   TCP_MAX_MSS : constant Mss_Upper_Bound := 1_430;
#end if;

   type Mss_Size is range 1 .. TCP_MAX_MSS
   with Size => unsigned_short'Size;

   -- Default maximum segment size
#if TCP_DEFAULT_MSS'Defined then
   TCP_DEFAULT_MSS : constant Mss_Size := $TCP_DEFAULT_MSS;
#else
   TCP_DEFAULT_MSS : constant Mss_Size := 536;
#end if;

   subtype Rto_Systime_Max is Systime range 1000 .. Systime'Last;
   -- Maximum retransmission timeout
#if TCP_MAX_RTO'Defined then
   TCP_MAX_RTO : constant Rto_Systime_Max := $TCP_MAX_RTO;
#else
   TCP_MAX_RTO : constant Rto_Systime_Max := 60000;
#end if;

   subtype Rto_Systime is Systime range 100 .. TCP_MAX_RTO;
   -- Initial retransmission timeout
#if TCP_INITIAL_RTO'Defined then
   TCP_INITIAL_RTO : constant Rto_Systime := $TCP_INITIAL_RTO;
#else
   TCP_INITIAL_RTO : constant Rto_Systime := 1000;
#end if;

   -- Minimum retransmission timeout
#if TCP_MIN_RTO'Defined then
   TCP_MIN_RTO : constant Rto_Systime := $TCP_MIN_RTO;
#else
   TCP_MIN_RTO : constant Rto_Systime := 1000;
#end if;

   -- Size of the congestion window after the three-way handshake is completed
#if TCP_INITIAL_WINDOW'Defined then
   TCP_INITIAL_WINDOW : constant unsigned_short := $TCP_INITIAL_WINDOW;
#else
   TCP_INITIAL_WINDOW : constant unsigned_short := 3;
#end if;

#if TCP_MAX_SACK_BLOCKS'Defined then
   TCP_MAX_SACK_BLOCKS : constant Positive := $TCP_MAX_SACK_BLOCKS;
#else
   TCP_MAX_SACK_BLOCKS : constant Positive := 4;
#end if;

   -- Override timeout (should be in the range 0.1 to 1 seconds)
   TCP_OVERRIDE_TIMEOUT : constant Systime := 500;

   type Tcp_State is
     (TCP_STATE_CLOSED,
      TCP_STATE_LISTEN,
      TCP_STATE_SYN_SENT,
      TCP_STATE_SYN_RECEIVED,
      TCP_STATE_ESTABLISHED,
      TCP_STATE_CLOSE_WAIT,
      TCP_STATE_LAST_ACK,
      TCP_STATE_FIN_WAIT_1,
      TCP_STATE_FIN_WAIT_2,
      TCP_STATE_CLOSING,
      TCP_STATE_TIME_WAIT);

   for Tcp_State'Size use int'Size;

   for Tcp_State use
      (TCP_STATE_CLOSED       => 0,
       TCP_STATE_LISTEN       => 1,
       TCP_STATE_SYN_SENT     => 2,
       TCP_STATE_SYN_RECEIVED => 3,
       TCP_STATE_ESTABLISHED  => 4,
       TCP_STATE_CLOSE_WAIT   => 5,
       TCP_STATE_LAST_ACK     => 6,
       TCP_STATE_FIN_WAIT_1   => 7,
       TCP_STATE_FIN_WAIT_2   => 8,
       TCP_STATE_CLOSING      => 9,
       TCP_STATE_TIME_WAIT    => 10
      );

   function Tcp_State_Convert (State : int) return Tcp_State is
      (if State = 0 then TCP_STATE_CLOSED
       elsif State = 1 then TCP_STATE_LISTEN
       elsif State = 2 then TCP_STATE_SYN_SENT
       elsif State = 3 then TCP_STATE_SYN_RECEIVED
       elsif State = 4 then TCP_STATE_ESTABLISHED
       elsif State = 5 then TCP_STATE_CLOSE_WAIT
       elsif State = 6 then TCP_STATE_LAST_ACK
       elsif State = 7 then TCP_STATE_FIN_WAIT_1
       elsif State = 8 then TCP_STATE_FIN_WAIT_2
       elsif State = 9 then TCP_STATE_CLOSING
       else TCP_STATE_TIME_WAIT);

   type TCP_Congest_State is new int;
      TCP_CONGEST_STATE_IDLE           : constant Tcp_Congest_State := 0;
      TCP_CONGEST_STATE_RECOVERY       : constant Tcp_Congest_State := 1;
      TCP_CONGEST_STATE_LOSS_RECOVERY  : constant Tcp_Congest_State := 2;

   subtype Tcp_Flags is uint8;

   TCP_FLAG_FIN : constant Tcp_Flags := 1;
   TCP_FLAG_SYN : constant Tcp_Flags := 2;
   TCP_FLAG_RST : constant Tcp_Flags := 4;
   TCP_FLAG_PSH : constant Tcp_Flags := 8;
   TCP_FLAG_ACK : constant Tcp_Flags := 16;
   TCP_FLAG_URG : constant Tcp_Flags := 32;

   type Chunk_Desc_Array_Index is range 0 .. ((TCP_MAX_TX_BUFFER_SIZE + NET_MEM_POOL_BUFFER_SIZE - 1) / NET_MEM_POOL_BUFFER_SIZE);
   type Chunk_Desc_Array is array (Chunk_Desc_Array_Index) of Chunk_Desc
   with
      Object_Size =>
         (((TCP_MAX_TX_BUFFER_SIZE + NET_MEM_POOL_BUFFER_SIZE - 1) / NET_MEM_POOL_BUFFER_SIZE) + 1) * (32 + System.Word_Size);

   type Tcp_Tx_Buffer is record
      chunkCount    : unsigned;
      maxChunkCound : unsigned;
      chunk         : Chunk_Desc_Array;
   end record
   with
      Convention => C,
      Object_Size =>
         64 + (((TCP_MAX_TX_BUFFER_SIZE + NET_MEM_POOL_BUFFER_SIZE - 1) / NET_MEM_POOL_BUFFER_SIZE) + 1) * (32 + System.Word_Size);

   type Tcp_Rx_Buffer is record
      chunkCount    : unsigned;
      maxChunkCound : unsigned;
      chunk         : Chunk_Desc_Array;
   end record
   with
      Convention => C;

   type Tcp_Timer is record
      running   : Bool;
      startTime : Systime;
      interval  : Systime;
   end record
   with
      Convention => C;

   type Tcp_Queue_Item is record
      length : unsigned;
   end record
   with
      Convention => C;

   type Tcp_Sack_Block is record
      leftEdge  : unsigned_long;
      rightEdge : unsigned_long;
   end record
   with
      Convention => C;

   type SackBlockArray is array (0 .. 3) of Tcp_Sack_Block;

   type Tcp_Syn_Queue_Item;
   type Tcp_Syn_Queue_Item_Acc is access Tcp_Syn_Queue_Item;
   type Tcp_Syn_Queue_Item is
    record
      Next          : Tcp_Syn_Queue_Item_Acc;
      Net_Interface : System.Address;
      Src_Addr      : IpAddr;
      Src_Port      : Port;
      Dest_Addr     : IpAddr;
      Isn           : unsigned;
      Mss           : Mss_Size;
    end record
      with Convention => C;

   function Tcp_Syn_Queue_Item_Model
      (Queue : access constant Tcp_Syn_Queue_Item) return Boolean is
      (Queue = null or else
         (Is_Initialized_Ip (Queue.Src_Addr) and then
          Queue.Src_Port > 0 and then
          Is_Initialized_Ip (Queue.Dest_Addr) and then
          Tcp_Syn_Queue_Item_Model (Queue.Next)))
      with
         Ghost,
         Annotate => (GNATprove, Terminating);
   pragma Annotate
     (GNATprove, False_Positive,
      "call to ""Is_Initialized_Ip"" might be nonterminating",
      "Recursive calls occur on strictly smaller structure");
   pragma Annotate
      (GNATprove, False_Positive,
      """Tcp_Syn_Queue_Item_Model"" is recursive, terminating annotation could be incorrect",
      "Recursive calls occur on strictly smaller structure");

   -- type Tcp_Header is record
   --    Src_Port       : Port;           -- 0-1
   --    Dest_Port      : Port;           -- 2-3
   --    Seq_Num        : unsigned;       -- 4-7
   --    Ack_Num        : unsigned;       -- 8-11
   --    Reserved1      : uint8;          -- 12
   --    Data_Offset    : uint8;
   --    Flags          : uint8;          -- 13
   --    Reserved2      : uint8;
   --    Window         : unsigned_short; -- 14-15
   --    Checksum       : unsigned_short; -- 16-17
   --    Urgent_Pointer : unsigned_short; -- 18-19
   --    Options        : uint8;          -- 20
   -- end record;

   -- for Tcp_Header use record
   --    Src_Port       at 0 range   0 .. 15;
   --    Dest_Port      at 0 range  16 .. 31;
   --    Seq_Num        at 0 range  32 .. 63;
   --    Ack_Num        at 0 range  64 .. 95;
   --    Reserved1      at 0 range  96 .. 99;
   --    Data_Offset    at 0 range 100 .. 103;
   --    Flags          at 0 range 104 .. 109;
   --    Reserved2      at 0 range 110 .. 111;
   --    Window         at 0 range 112 .. 127;
   --    Checksum       at 0 range 128 .. 143;
   --    Urgent_Pointer at 0 range 144 .. 159;
   --    Options        at 0 range 160 .. 167;
   -- end record;

   -- for Tcp_Header'Scalar_Storage_Order use System.High_Order_First;

end Tcp_Type;
