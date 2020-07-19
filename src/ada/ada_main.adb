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
      Sock : Socket;
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
      Error : Error_T;
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
      Get_Host_By_Name("httpbin.org", ServerAddr, HOST_NAME_RESOLVER_ANY, Error);
      if Error /= NO_ERROR then
         return;
      end if;

      Socket_Open (Sock, SOCKET_TYPE_STREAM, SOCKET_IP_PROTO_TCP);
      if Sock = null then
         return;
      end if;

      Socket_Set_Timeout (Sock, 10_000);

      Socket_Connect (Sock, ServerAddr, 80, Error);
      if Error /= NO_ERROR then
         goto End_Of_Loop;
      end if;

      Socket_Send (Sock, Request, Written, 0, Error);
      if Error /= NO_ERROR then
         goto End_Of_Loop;
      end if;

      loop
            pragma Loop_Invariant
               (Sock /= null and then
                TCP_Rel_Iter (Model(Sock)'Loop_Entry, Model(Sock)));
            Socket_Receive (Sock, Buf, Received, 0, Error);
            exit when Error = ERROR_END_OF_STREAM;
            if Error /= NO_ERROR then
               goto End_Of_Loop;
            end if;
            Print_String (Buf, int(Received)); -- For debug purpose
      end loop;
      Socket_Shutdown(Sock, SOCKET_SD_BOTH, Error);

      <<End_Of_Loop>>
      Socket_Close (Sock);
   end HTTP_Client_Test;

   procedure HTTP_Server_Test is
      Sock              : Socket;
      Sock_Client       : Socket;
      IPAddr_Client     : IpAddr with Unreferenced;
      Port_Client       : Port with Unreferenced;
   begin
      Socket_Open (Sock, SOCKET_TYPE_STREAM, SOCKET_IP_PROTO_TCP);
      if Sock = null then
         return;
      end if;

      Socket_Bind (Sock, IP_ADDR_ANY, 80);

      Socket_Listen (Sock, 0);

      Socket_Accept (Sock, IPAddr_Client, Port_Client, Sock_Client);

      Socket_Close (Sock);
      if Sock_Client /= null then
         Socket_Close (Sock_Client);
      end if;

   end HTTP_Server_Test;

end Ada_Main;
