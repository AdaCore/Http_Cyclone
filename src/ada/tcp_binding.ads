with Error_H; use Error_H;
with System;
with Interfaces.C; use Interfaces.C;
with Ip; use Ip;
with Tcp_Type; use Tcp_Type;
with Common_Type; use Common_Type;
with Socket_Type; use Socket_Type;

package Tcp_binding is

    function Tcp_Init return Error_T
    with
        Import => True,
        Convention => C,
        External_Name => "tcpInit";

    function Tcp_Get_Dynamic_Port return Port
    with
        Import => True,
        Convention => C,
        External_Name => "tcpGetDynamicPort";

    function Tcp_Connect (Sock : Socket; remoteIpAddr : System.Address; remotePort : Port)
    return unsigned
    with
        Import => True,
        Convention => C,
        External_Name => "tcpConnect";

    function Tcp_Listen (Sock : Socket; backlog : unsigned)
    return unsigned
    with
        Import => True,
        Convention => C,
        External_Name => "tcpListen";

    function Tcp_Accept (Sock : Socket; Client_Ip_Addr : out IpAddr; unsigned : out Port)
    return Socket
    with
        Import => True,
        Convention => C,
        External_Name => "tcpAccept";
    
    function Tcp_Send (Sock : Socket ; Data : char_array ; Length : unsigned; Written : out unsigned ; Flags : unsigned)
    return unsigned
    with
        Import => True,
        Convention => C,
        External_Name => "tcpSend";

    function Tcp_Receive (Sock : socket; Data : out char_array; Size : unsigned; Received : out unsigned ; Flags : unsigned)
    return unsigned
    with
        Import => True,
        Convention => C,
        External_Name => "tcpReceive";
    
    function Tcp_Shutdown (Sock : Socket ; how : unsigned)
    return unsigned
    with
        Import => True,
        Convention => C,
        External_Name => "tcpShutdown";
    
    function Tcp_Abort (Sock : Socket)
    return unsigned
    with
        Import => True,
        Convention => C,
        External_Name => "tcpAbort";

    function Tcp_Get_State (Sock : Socket)
    return Tcp_State
    with
        Import => True,
        Convention => C,
        External_Name => "tcpGetState";
    
    function Tcp_Kill_Oldest_Connection
    return Socket
    with
        Import => True,
        Convention => C,
        External_Name => "tcpKillOldestConnection";

end Tcp_binding;
