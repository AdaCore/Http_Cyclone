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
with Error_H;      use Error_H;
with Interfaces.C; use Interfaces.C;
with Ip;           use Ip;
with System;
with Socket_Types; use Socket_Types;

package Udp_Binding
   with SPARK_Mode
is

   --------------
   -- Udp_Init --
   --------------

   function Udp_Init return unsigned
      with
        Import        => True,
        Convention    => C,
        External_Name => "udpInit";

   function Udp_Get_Dynamic_Port return Port
      with
        Global        => null,
        Import        => True,
        Convention    => C,
        External_Name => "udpGetDynamicPort";

   function Udp_Process_Datagram
      (N_Interface  : System.Address;
       Pseudo_Header : System.Address;
       Buffer       : System.Address;
       Offset       : unsigned;
       Ancillary    : System.Address) return unsigned
      with
        Import        => True,
        Convention    => C,
        External_Name => "udpProcessDatagram";

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
   with
      Global => null,
      Pre => Sock.S_Type = SOCKET_TYPE_DGRAM,
      Post => Basic_Model(Sock) = Basic_Model(Sock)'Old and then
              Written <= Data'Length;

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
   with
      Global => null,
      Pre => Sock.S_Type = SOCKET_TYPE_DGRAM,
      Post => Basic_Model(Sock) = Basic_Model(Sock)'Old;

end Udp_Binding;
