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

with Net_Mem_Interface; use Net_Mem_Interface;
with Os;                use Os;
with Socket_Helper;     use Socket_Helper;
with System;
with Tcp_Fsm_Binding;   use Tcp_Fsm_Binding;
with Udp_Binding;       use Udp_Binding;

package body Socket_Interface
   with SPARK_Mode
is

   ----------------------
   -- Get_Host_By_Name --
   ----------------------

   procedure Get_Host_By_Name
     (Server_Name    :     char_array;
      Server_Ip_Addr : out IpAddr;
      Flags          :     Host_Resolver;
      Error          : out Error_T)
   is begin
      Get_Host_By_Name_H
        (Server_Name, Server_Ip_Addr, unsigned (Flags), Error);
   end Get_Host_By_Name;

   -----------------
   -- Socket_Open --
   -----------------

   procedure Socket_Open
     (Sock       : out Socket;
      S_Type     :     Socket_Type;
      S_Protocol :     Socket_Protocol)
   is
      Error    : Error_T;
      P        : Port;
      Protocol : Socket_Protocol := S_Protocol;
   begin
      --  Initialize socket handle
      Sock := null;
      Os_Acquire_Mutex (Net_Mutex);

      case S_Type is
         when SOCKET_TYPE_STREAM =>
            --  Always use TCP as underlying transport protocol
            Protocol := SOCKET_IP_PROTO_TCP;
            --  Get an ephemeral port number
            Tcp_Get_Dynamic_Port (P);
            Error := NO_ERROR;
         when SOCKET_TYPE_DGRAM =>
            --  Always use UDP as underlying transport protocol
            Protocol := SOCKET_IP_PROTO_UDP;
            --  Get an ephemeral port number
            P     := Udp_Get_Dynamic_Port;
            Error := NO_ERROR;
         when SOCKET_TYPE_RAW_IP | SOCKET_TYPE_RAW_ETH =>
            P     := 0;
            Error := NO_ERROR;
         when others =>
            P     := 0;
            Error := ERROR_INVALID_PARAMETER;
      end case;

      if Error = NO_ERROR then
         for I in Socket_Table'Range loop
            if Socket_Table (I).S_Type = SOCKET_TYPE_UNUSED
            then
               --  Save socket handle
               Get_Socket_From_Table (I, Sock);
               --  We are done
               exit;
            end if;
         end loop;

         if Sock = null then
            --  Kill the oldest connection in the TIME-WAIT state whenever the
            --  socket table runs out of space
            Tcp_Kill_Oldest_Connection (Sock);
         end if;

         --  Check whether the current entry is free
         if Sock /= null then
            --  Reset Socket
            --  Maybe there is a simplest way to perform that in Ada
            Sock.S_Type                := S_Type;
            Sock.S_Protocol            := Protocol;
            Sock.S_Local_Port          := P;
            Sock.S_Timeout             := Systime'Last;
            Sock.S_Remote_Ip_Addr.Length := 0;
            Sock.S_localIpAddr.Length  := 0;
            Sock.S_Remote_Port         := 0;
            Sock.S_Net_Interface       := System.Null_Address;
            Sock.S_TTL                 := 0;
            Sock.S_Multicast_TTL       := 0;
            Sock.S_Errno_Code          := 0;
            Sock.S_Event_Mask          := 0;
            Sock.S_Event_Flags         := 0;
            Sock.S_User_Event          := null;
            pragma Annotate (GNATprove, False_Positive,
                             "memory leak might occur",
                             "Memory should already be free");
            Sock.State                 := TCP_STATE_CLOSED;
            Sock.owned_Flag            := False;
            Sock.closed_Flag           := False;
            Sock.reset_Flag            := False;
            Sock.smss                  := TCP_DEFAULT_MSS;
            Sock.rmss                  := TCP_DEFAULT_MSS;
            Sock.iss                   := 0;
            Sock.irs                   := 0;
            Sock.sndUna                := 0;
            Sock.sndNxt                := 0;
            Sock.sndUser               := 0;
            Sock.sndWnd                := 0;
            Sock.maxSndWnd             := 0;
            Sock.sndWl1                := 0;
            Sock.sndWl2                := 0;
            Sock.rcvNxt                := 0;
            Sock.rcvUser               := 0;
            Sock.rcvWnd                := 0;
            Sock.rttBusy               := False;
            Sock.rttSeqNum             := 0;
            Sock.rettStartTime         := 0;
            Sock.srtt                  := 0;
            Sock.rttvar                := 0;
            Sock.rto                   := 0;
            Sock.congestState          := TCP_CONGEST_STATE_IDLE;
            Sock.cwnd                  := 0;
            Sock.ssthresh              := 0;
            Sock.dupAckCount           := 0;
            Sock.n                     := 0;
            Sock.recover               := 0;
            Sock.txBuffer.chunkCount   := 0;
            Sock.txBufferSize          := TCP_DEFAULT_TX_BUFFER_SIZE;
            Sock.rxBuffer.chunkCount   := 0;
            Sock.rxBufferSize          := TCP_DEFAULT_RX_BUFFER_SIZE;
            Sock.retransmitQueue       := System.Null_Address;
            Sock.retransmitCount       := 0;
            Sock.synQueue              := null;
            pragma Annotate (GNATprove, False_Positive,
                             "memory leak might occur",
                             "Memory should already be free");
            --  Limit the number of pending connections
            Sock.synQueueSize          := TCP_DEFAULT_SYN_QUEUE_SIZE;
            Sock.wndProbeCount         := 0;
            Sock.wndProbeInterval      := 0;
            Sock.sackPermitted         := False;
            Sock.sackBlockCount        := 0;
            Sock.receiveQueue          := null;
            pragma Annotate (GNATprove, False_Positive,
                             "memory leak might occur",
                             "Memory should already be free");
         end if;
      end if;

      Os_Release_Mutex (Net_Mutex);
   end Socket_Open;

   ------------------------
   -- Socket_Set_Timeout --
   ------------------------

   procedure Socket_Set_Timeout
     (Sock    : in out Not_Null_Socket;
      Timeout :        Systime)
   is
   begin
      Os_Acquire_Mutex (Net_Mutex);
      Sock.S_Timeout := Timeout;
      Os_Release_Mutex (Net_Mutex);
   end Socket_Set_Timeout;

   --------------------
   -- Socket_Set_Ttl --
   --------------------

   procedure Socket_Set_Ttl
     (Sock : in out Not_Null_Socket;
      Ttl  :        Ttl_Type)
   is
   begin
      Os_Acquire_Mutex (Net_Mutex);
      Sock.S_TTL := unsigned_char (Ttl);
      Os_Release_Mutex (Net_Mutex);
   end Socket_Set_Ttl;

   ------------------------------
   -- Socket_Set_Multicast_Ttl --
   ------------------------------

   procedure Socket_Set_Multicast_Ttl
     (Sock : in out Not_Null_Socket;
      Ttl  :        Ttl_Type)
   is
   begin
      Os_Acquire_Mutex (Net_Mutex);
      Sock.S_Multicast_TTL := unsigned_char (Ttl);
      Os_Release_Mutex (Net_Mutex);
   end Socket_Set_Multicast_Ttl;

   --------------------
   -- Socket_Connect --
   --------------------

   procedure Socket_Connect
     (Sock           : in out Not_Null_Socket;
      Remote_Ip_Addr : in     IpAddr;
      Remote_Port    : in     Port;
      Error          :    out Error_T)
   is
   begin
      --  Connection oriented socket?
      if Sock.S_Type = SOCKET_TYPE_STREAM then
         Os_Acquire_Mutex (Net_Mutex);
         Tcp_Process_Segment (Sock);
         --  Establish TCP connection
         Tcp_Connect (Sock, Remote_Ip_Addr, Remote_Port, Error);
         Os_Release_Mutex (Net_Mutex);

         --  Connectionless socket?
      elsif Sock.S_Type = SOCKET_TYPE_DGRAM then
         Sock.S_Remote_Ip_Addr := Remote_Ip_Addr;
         Sock.S_Remote_Port  := Remote_Port;
         Error               := NO_ERROR;

         --  Raw Socket?
      elsif Sock.S_Type = SOCKET_TYPE_RAW_IP then
         Sock.S_Remote_Ip_Addr := Remote_Ip_Addr;
         Error               := NO_ERROR;
      else
         Error := ERROR_INVALID_SOCKET;
      end if;
   end Socket_Connect;

   --------------------
   -- Socket_Send_To --
   --------------------

   procedure Socket_Send_To
     (Sock         : in out Not_Null_Socket;
      Dest_Ip_Addr :        IpAddr;
      Dest_Port    :        Port;
      Data         : in     Send_Buffer;
      Written      :    out Natural;
      Flags        :        Socket_Flags;
      Error        :    out Error_T)
   is
   begin
      Written := 0;

      Os_Acquire_Mutex (Net_Mutex);
      if Sock.S_Type = SOCKET_TYPE_STREAM then
         --  INTERFERENCES
         Tcp_Process_Segment (Sock);
         Tcp_Send (Sock, Data, Written, Flags, Error);
      elsif Sock.S_Type = SOCKET_TYPE_DGRAM then
         Udp_Send_Datagram
           (Sock, Dest_Ip_Addr, Dest_Port, Data, Written, Flags, Error);
      else
         Error := ERROR_INVALID_SOCKET;
      end if;
      Os_Release_Mutex (Net_Mutex);
   end Socket_Send_To;

   -----------------
   -- Socket_Send --
   -----------------

   procedure Socket_Send
     (Sock    : in out Not_Null_Socket;
      Data    : in     Send_Buffer;
      Written :    out Natural;
      Flags   :        Socket_Flags;
      Error   :    out Error_T)
   is
   begin
      Written := 0;

      Os_Acquire_Mutex (Net_Mutex);
      if Sock.S_Type = SOCKET_TYPE_STREAM then
         --  INTERFERENCES
         Tcp_Process_Segment (Sock);
         Tcp_Send (Sock, Data, Written, Flags, Error);
      elsif Sock.S_Type = SOCKET_TYPE_DGRAM then
         --  @TODO : See how to improve this part without using .all
         Udp_Send_Datagram
            (Sock => Sock,
             Dest_Ip_Addr => IpAddr'(Length => Sock.S_Remote_Ip_Addr.Length,
                                     Ip     => Sock.S_Remote_Ip_Addr.Ip),
             Dest_Port => Sock.S_Remote_Port,
             Data => Data,
             Written => Written,
             Flags => Flags,
             Error => Error);
      else
         Error := ERROR_INVALID_SOCKET;
      end if;
      Os_Release_Mutex (Net_Mutex);
   end Socket_Send;

   -----------------------
   -- Socket_Receive_Ex --
   -----------------------

   procedure Socket_Receive_Ex
     (Sock         : in out Not_Null_Socket;
      Src_Ip_Addr  :    out IpAddr;
      Src_Port     :    out Port;
      Dest_Ip_Addr :    out IpAddr;
      Data         :    out Received_Buffer;
      Received     :    out Natural;
      Flags        :        Socket_Flags;
      Error        :    out Error_T)
   is
   begin

      Os_Acquire_Mutex (Net_Mutex);
      if Sock.S_Type = SOCKET_TYPE_STREAM then
         --  INTERFERENCES
         Tcp_Process_Segment (Sock);
         Tcp_Receive (Sock, Data, Received, Flags, Error);
         --  Save the source IP address
         Src_Ip_Addr  := Sock.S_Remote_Ip_Addr;
         --  Save the source port number
         Src_Port     := Sock.S_Remote_Port;
         --  Save the destination IP address
         Dest_Ip_Addr := Sock.S_localIpAddr;
      elsif Sock.S_Type = SOCKET_TYPE_DGRAM then
         Udp_Receive_Datagram
            (Sock         => Sock,
             Src_Ip_Addr  => Src_Ip_Addr,
             Src_Port     => Src_Port,
             Dest_Ip_Addr => Dest_Ip_Addr,
             Data         => Data,
             Received     => Received,
             Flags        => Flags,
             Error        => Error);
      else
         Src_Ip_Addr  := Sock.S_Remote_Ip_Addr;
         Src_Port     := Sock.S_Remote_Port;
         Dest_Ip_Addr := Sock.S_localIpAddr;
         Error        := ERROR_INVALID_SOCKET;
         Received     := 0;
         Data         := (others => nul);
      end if;
      Os_Release_Mutex (Net_Mutex);
   end Socket_Receive_Ex;

   --------------------
   -- Socket_Receive --
   --------------------

   procedure Socket_Receive
     (Sock     : in out Not_Null_Socket;
      Data     :    out Received_Buffer;
      Received :    out Natural;
      Flags    :        Socket_Flags;
      Error    :    out Error_T)
   is
      Ignore_Src_Ip, Ignore_Dest_Ip : IpAddr;
      Ignore_Src_Port               : Port;
   begin
      Socket_Receive_Ex
        (Sock, Ignore_Src_Ip, Ignore_Src_Port, Ignore_Dest_Ip, Data, Received,
         Flags, Error);
   end Socket_Receive;

   ---------------------
   -- Socket_Shutdown --
   ---------------------

   procedure Socket_Shutdown
     (Sock  : in out Not_Null_Socket;
      How   :        Socket_Shutdown_Flags;
      Error :    out Error_T)
   is
   begin
      Os_Acquire_Mutex (Net_Mutex);
      Tcp_Process_Segment (Sock);
      Tcp_Shutdown (Sock, How, Error);
      Os_Release_Mutex (Net_Mutex);
   end Socket_Shutdown;

   ------------------
   -- Socket_Close --
   ------------------

   procedure Socket_Close (Sock : in out Socket) is
      Ignore_Error : Error_T;
   begin
      --  Get exclusive access
      Os_Acquire_Mutex (Net_Mutex);

      if Sock.S_Type = SOCKET_TYPE_STREAM then
         Tcp_Process_Segment (Sock);
         Tcp_Abort (Sock, Ignore_Error);
      elsif Sock.S_Type in SOCKET_TYPE_DGRAM
                         | SOCKET_TYPE_RAW_IP
                         | SOCKET_TYPE_RAW_ETH
      then
         --  @TODO Have a look at this section to see if the code is
         --  valid, in particular in what is done with pointers.
         declare
            --  Point to the first item in the receive queue
            Queue_Item : Socket_Queue_Item_Acc := Sock.receiveQueue;
         begin
            --  Purge the receive queue
            while Queue_Item /= null loop
               declare
                  --  Keep track of the next item in the queue
                  Next_Queue_Item : constant Socket_Queue_Item_Acc
                    := Queue_Item.Next;
               begin
                  Queue_Item.Next := null;
                  --  Free previously allocated memory
                  --  netBufferFree(queueItem.Buffer); in the c code
                  Net_Buffer_Free (Queue_Item);
                  --  Point to the next item
                  Queue_Item := Next_Queue_Item;
               end;
            end loop;
            Sock.receiveQueue := null;
         end;

            --  Mark the socket as closed
            Sock.S_Type := SOCKET_TYPE_UNUSED;

            --  Fake free the socket
            Free_Socket (Sock);
      end if;

      --  Release exclusive access
      Os_Release_Mutex (Net_Mutex);
   end Socket_Close;

   -------------------------------
   -- Socket_Set_Tx_Buffer_Size --
   -------------------------------

   procedure Socket_Set_Tx_Buffer_Size
     (Sock : in out Not_Null_Socket;
      Size :        Tx_Buffer_Size)
   is
   begin
      Sock.txBufferSize := Size;
   end Socket_Set_Tx_Buffer_Size;

   -------------------------------
   -- Socket_Set_Rx_Buffer_Size --
   -------------------------------

   procedure Socket_Set_Rx_Buffer_Size
     (Sock : in out Not_Null_Socket;
      Size :        Rx_Buffer_Size)
   is
   begin
      Sock.rxBufferSize := Size;
   end Socket_Set_Rx_Buffer_Size;

   -----------------
   -- Socket_Bind --
   -----------------

   procedure Socket_Bind
     (Sock          : in out Not_Null_Socket;
      Local_Ip_Addr :        IpAddr;
      Local_Port    :        Port)
   is
   begin
      Sock.S_localIpAddr := Local_Ip_Addr;
      Sock.S_Local_Port  := Local_Port;
   end Socket_Bind;

   -------------------
   -- Socket_Listen --
   -------------------

   procedure Socket_Listen
     (Sock    : in out Not_Null_Socket;
      Backlog :        Natural)
      --  Error   :    out Error_T)
   is
   begin
      Os_Acquire_Mutex (Net_Mutex);
      Tcp_Listen (Sock, unsigned (Backlog));
      Os_Release_Mutex (Net_Mutex);
   end Socket_Listen;

   -------------------
   -- Socket_Accept --
   -------------------

   procedure Socket_Accept
     (Sock           : in out Not_Null_Socket;
      Client_Ip_Addr :    out IpAddr;
      Client_Port    :    out Port;
      Client_Socket  :    out Socket)
   is
   begin
      Tcp_Accept (Sock, Client_Ip_Addr, Client_Port, Client_Socket);
   end Socket_Accept;

end Socket_Interface;
