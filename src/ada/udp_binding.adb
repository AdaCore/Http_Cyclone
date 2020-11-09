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

package body Udp_Binding
   with SPARK_Mode => Off
is

   -----------------------
   -- Udp_Send_Datagram --
   -----------------------

   procedure Udp_Send_Datagram
      (Sock         : in out Not_Null_Socket;
       Dest_Ip_Addr : in     IpAddr;
       Dest_Port    : in     Port;
       Data         : in     Send_Buffer;
       Written      :    out Natural;
       Flags        : in     Socket_Flags;
       Error        :    out Error_T)
   is
      function udpSendDatagram
         (Sock         :     Socket;
          Dest_Ip_Addr :     System.Address;
          Dest_Port    :     Port;
          Data         :     char_array;
          Length       :     unsigned;
          Written      : out unsigned;
          Flags        :     unsigned) return unsigned
      with
        Import        => True,
        Convention    => C,
        External_Name => "udpSendDatagram";
   begin
      Written := 0;
      Error := Error_T'Enum_Val (udpSendDatagram (Sock, Dest_Ip_Addr'Address,
                                 Dest_Port, char_array (Data),
                                 Data'Length,
                                 unsigned (Written), Flags));
   end Udp_Send_Datagram;

   --------------------------
   -- Udp_Receive_Datagram --
   --------------------------

   procedure Udp_Receive_Datagram
      (Sock         : in out Not_Null_Socket;
       Src_Ip_Addr  :    out IpAddr;
       Src_Port     :    out Port;
       Dest_Ip_Addr :    out IpAddr;
       Data         :    out Received_Buffer;
       Received     :    out Natural;
       Flags        : in     Socket_Flags;
       Error        :    out Error_T)
   is
      function udpReceiveDatagram
         (Sock      : Socket;
          srcIpAddr : System.Address;
          srcPort   : out Port;
          destIpAddr : System.Address;
          data      : out char_array;
          size      : unsigned;
          received  : out unsigned;
          flags     : unsigned) return unsigned
      with
         Import        => True,
         Convention    => C,
         External_Name => "udpReceiveDatagram";

      Received_Data : char_array (size_t (Data'First) .. size_t (Data'Last));
   begin
      Received := 0;
      Error := Error_T'Enum_Val (udpReceiveDatagram (Sock,
                                 Src_Ip_Addr'Address, Src_Port,
                                 Dest_Ip_Addr'Address,
                                 Received_Data, Data'Length,
                                 unsigned (Received), Flags));
      Data := Received_Buffer (Received_Data);

   end Udp_Receive_Datagram;
end Udp_Binding;
