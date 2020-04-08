with Socket_interface; use Socket_interface;
with socket_binding; use socket_binding;
with Ip; use Ip;
with Interfaces.C; use Interfaces.C;
with Error_H; use Error_H;

package body Ada_Main 
with SPARK_Mode
is
      
    procedure HTTP_Client_Test is
        Sock : Socket_Struct;
        ServerAddr : IpAddr;
        Request : constant char_array := "GET /anything HTTP/1.1\r\nHost: httpbin.org\r\nConnection: close\r\n\r\n";
        Buf : char_array (1 .. 128);
        Ret : Integer;
        Error : Error_T;
    begin
        Get_Host_By_Name("httpbin.org", ServerAddr, Error);
        if Error /= NO_ERROR then
            return;
        end if;

        Socket_Open (Sock, SOCKET_TYPE_STREAM, SOCKET_IP_PROTO_TCP);
        Socket_Set_Timeout(Sock, 30000, Error);
        if Error /= NO_ERROR then
            return;
        end if;

        Socket_Connect(Sock, ServerAddr, 80, Error);
        if Error /= NO_ERROR then
            return;
        end if;

        Socket_Send(Sock, Request, Error);
        if Error /= NO_ERROR then
            return;
        end if;

        loop
            Socket_Receive (Sock, Buf, Error);
            exit when Error = ERROR_END_OF_STREAM;
            if Error /= NO_ERROR then
                return;
            end if;
        end loop;
        Socket_Shutdown(Sock, Error);
        if Error /= NO_ERROR then
            return;
        end if;

        Socket_Close(Sock);
    end HTTP_Client_Test;

end Ada_Main;
