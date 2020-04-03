with Socket_interface; use Socket_interface;
with socket_binding; use socket_binding;
with Ip; use Ip;
with Interfaces.C; use Interfaces.C;

package body Ada_Main is
      
    procedure HTTP_Client_Test is
        Sock : Socket_Struct;
        ServerAddr : IpAddr;
        Request : constant char_array := "GET /anything HTTP/1.1\r\nHost: httpbin.org\r\nConnection: close\r\n\r\n";
        Buf : char_array (1 .. 128);
        Ret : Integer;
    begin
        Get_Host_By_Name("httpbin.org", ServerAddr);
        Socket_Open (Sock, SOCKET_TYPE_STREAM, SOCKET_IP_PROTO_TCP);
        Socket_Set_Timeout(Sock, 30000);
        Socket_Connect(Sock, ServerAddr, 80);
        Socket_Send(Sock, Request);
        loop
           Ret := Socket_Receive (Sock, Buf);
           exit when Ret /= 0;
        end loop;
        Socket_Shutdown(Sock);
        Socket_Close(Sock);
    end HTTP_Client_Test;

end Ada_Main;
