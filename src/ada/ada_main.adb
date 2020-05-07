pragma Ada_2020;

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
        Request : constant char_array := "GET /anything HTTP/1.1\r\nHost: httpbin.org\r\nConnection: close\r\n\r\n";
        Buf : char_array (1 .. 128) with Unreferenced;
        Error : Error_T;
        Written : Integer with Unreferenced;
        Received : Unsigned with Unreferenced;
    begin
        Get_Host_By_Name("httpbin.org", ServerAddr, HOST_NAME_RESOLVER_ANY, Error);
        if Error /= NO_ERROR then
            return;
        end if;

      Socket_Open (Sock, SOCKET_TYPE_STREAM, SOCKET_IP_PROTO_TCP);
      if Sock = null then
         return;
      end if;
      Socket_Set_Timeout (Sock, 30_000);

      Socket_Connect (Sock, ServerAddr, 80, Error);
      if Error /= NO_ERROR then
         return;
      end if;

      Socket_Send (Sock, Request, Written, Error);
      if Error /= NO_ERROR then
         return;
      end if;

        loop
            pragma Loop_Invariant (Sock.S_remoteIpAddr.length > 0 and Sock /= null);
            Socket_Receive (Sock, Buf, Received, Error);
            exit when Error = ERROR_END_OF_STREAM;
            if Error /= NO_ERROR then
                return;
            end if;
        end loop;
        Socket_Shutdown(Sock, SOCKET_SD_BOTH, Error);  -- ??? you might want to model the effects on the global state of changing Socket state
        if Error /= NO_ERROR then
           return;
        end if;

      Socket_Close (Sock);
   end HTTP_Client_Test;

   procedure HTTP_Server_Test is
      Error             : Error_T;
      Sock              : Socket;
      Sock_Client       : Socket with Unreferenced;
      IPAddr_Client     : IpAddr with Unreferenced;
      Port_Client       : Port with Unreferenced;
   begin
      Socket_Open (Sock, SOCKET_TYPE_STREAM, SOCKET_IP_PROTO_TCP);
      if Sock = null then
         return;
      end if;

      Socket_Bind (Sock, IP_ADDR_ANY, 80);

      Socket_Listen (Sock, 0, Error);
      if Error /= NO_ERROR then
         return;
      end if;

      Socket_Accept (Sock, IPAddr_Client, Port_Client, Sock_Client);

   end HTTP_Server_Test;

end Ada_Main;
