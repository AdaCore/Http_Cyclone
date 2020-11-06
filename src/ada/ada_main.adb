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

pragma Ada_2020;
pragma Unevaluated_Use_Of_Old (Allow);

with Error_H;          use Error_H;
with Ip;               use Ip;
with Interfaces.C;     use Interfaces.C;
with Common_Type;      use Common_Type;
with Socket_Types;     use Socket_Types;
with Socket_Interface; use Socket_Interface;

package body Ada_Main with
   SPARK_Mode
is

   procedure HTTP_Client_Test is
      Sock_Ignore : Socket;
      ServerAddr : IpAddr;
      End_Of_Line : constant Send_Buffer(1 .. 2) :=
               (1 => char'Val(13), 2 => char'Val(10));
      End_Of_Request : constant Send_Buffer (1 .. 1) :=
               (1 => char'Val(0));
      Request : constant Send_Buffer :=
               "GET /anything HTTP/1.1" & End_Of_Line &
               "Host: httpbin.org" & End_Of_Line &
               "Connection: close" & End_Of_Line & End_Of_Line
               & End_Of_Request;
      Buf : Received_Buffer (1 .. 128);
      Error_Ignore : Error_T;
      Written : Integer with Unreferenced;
      Received : Natural;

      procedure Print_String
         (str : Received_Buffer;
          length : int)
         with
            Import => True,
            Convention => C,
            External_Name => "debugString",
            Global => null;

   begin
      Get_Host_By_Name("httpbin.org", ServerAddr, HOST_NAME_RESOLVER_ANY, Error_Ignore);
      if Error_Ignore /= NO_ERROR then
         return;
      end if;

      Socket_Open (Sock_Ignore, SOCKET_TYPE_STREAM, SOCKET_IP_PROTO_TCP);
      if Sock_Ignore = null then
         return;
      end if;

      Socket_Set_Timeout (Sock_Ignore, 10_000);

      Socket_Connect (Sock_Ignore, ServerAddr, 80, Error_Ignore);
      if Error_Ignore /= NO_ERROR then
         goto End_Of_Loop;
      end if;

      Socket_Send (Sock_Ignore, Request, Written, 0, Error_Ignore);
      if Error_Ignore /= NO_ERROR then
         goto End_Of_Loop;
      end if;

      loop
            pragma Loop_Invariant
               (Sock_Ignore /= null and then
                TCP_Rel_Iter (Model(Sock_Ignore)'Loop_Entry, Model(Sock_Ignore)));
            Socket_Receive (Sock_Ignore, Buf, Received, 0, Error_Ignore);
            exit when Error_Ignore = ERROR_END_OF_STREAM;
            if Error_Ignore /= NO_ERROR then
               goto End_Of_Loop;
            end if;
            Print_String (Buf, int(Received)); -- For debug purpose
      end loop;
      Socket_Shutdown(Sock_Ignore, SOCKET_SD_BOTH, Error_Ignore);

      <<End_Of_Loop>>
      Socket_Close (Sock_Ignore);
   end HTTP_Client_Test;

   procedure HTTP_Server_Test is
      Sock_Ignore       : Socket;
      Sock_Client_Ignore: Socket;
      IPAddr_Client     : IpAddr with Unreferenced;
      Port_Client       : Port with Unreferenced;
   begin
      Socket_Open (Sock_Ignore, SOCKET_TYPE_STREAM, SOCKET_IP_PROTO_TCP);
      if Sock_Ignore = null then
         return;
      end if;

      Socket_Bind (Sock_Ignore, IP_ADDR_ANY, 80);

      Socket_Listen (Sock_Ignore, 0);

      Socket_Accept (Sock_Ignore, IPAddr_Client, Port_Client, Sock_Client_Ignore);

      Socket_Close (Sock_Ignore);
      if Sock_Client_Ignore /= null then
         Socket_Close (Sock_Client_Ignore);
      end if;

   end HTTP_Server_Test;

end Ada_Main;
