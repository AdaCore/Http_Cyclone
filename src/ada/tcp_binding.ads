with Error_H; use Error_H;
with Interfaces.C; use Interfaces.C;
with Ip; use Ip;
with Tcp_Type; use Tcp_Type;
with Common_Type; use Common_Type;
with Socket_Types; use Socket_Types;

package Tcp_binding 
    with SPARK_Mode
is

    -- Ephemeral ports are used for dynamic port assignment
    Tcp_Dynamic_Port : Port;

    function Tcp_Init return Error_T
    with
        Import => True,
        Convention => C,
        External_Name => "tcpInit";

    procedure Tcp_Get_Dynamic_Port (
               P : out Port
    )
    with
        Global => (
            Input => (SOCKET_EPHEMERAL_PORT_MIN, SOCKET_EPHEMERAL_PORT_MAX),
            In_Out => Tcp_Dynamic_Port
        ),
        Depends => (
            P => Tcp_Dynamic_Port,
            Tcp_Dynamic_Port => Tcp_Dynamic_Port,
            null => (SOCKET_EPHEMERAL_PORT_MIN, SOCKET_EPHEMERAL_PORT_MAX)
        ),
        Post => (
            P <= SOCKET_EPHEMERAL_PORT_MAX and then
            P >= SOCKET_EPHEMERAL_PORT_MIN and then
            Tcp_Dynamic_Port <= SOCKET_EPHEMERAL_PORT_MAX and then
            Tcp_Dynamic_Port >= SOCKET_EPHEMERAL_PORT_MIN
        );

    procedure Tcp_Connect (
        Sock : in out Socket;
        Remote_Ip_Addr : IpAddr;
        Remote_Port : Port;
        Error : out Error_T)
    with
        Depends => (
            Sock =>+ (Remote_Ip_Addr, Remote_Port),
            Error => (Sock, Remote_Port, Remote_Ip_Addr)
        );

    procedure Tcp_Listen (
            Sock : Socket;
            Backlog : unsigned;
            Error : out Error_T)
    with
        Depends => (
            Error => (Sock, Backlog)
        );

    procedure Tcp_Accept (
            Sock : Socket;
            Client_Ip_Addr : out IpAddr;
            Client_Port : out Port;
            Client_Socket : out Socket)
    with
        Depends => (
            Client_Ip_Addr => Sock,
            Client_Port => Sock,
            Client_Socket => Sock
        );
    
    procedure Tcp_Send (
            Sock : in out Socket;
            Data : char_array;
            Written : out Integer;
            Flags : unsigned;
            Error : out Error_T)
    with
        Depends => (
            Sock => (Sock, Flags),
            Written => (Sock, Data, Flags),
            Error => (Sock, Data, Flags)
        );

    procedure Tcp_Receive (
            Sock : in out Socket;
            Data : out char_array;
            Received : out unsigned;
            Flags : unsigned;
            Error : out Error_T)
    with
        Depends => (
            Error => (Sock, Flags),
            Sock =>+ Flags,
            Data => (Sock, Flags),
            Received => (Sock, Flags)
        ),
        Pre => Sock /= null and then Sock.S_remoteIpAddr.length /= 0,
        Contract_Cases => (
            Error = NO_ERROR => Sock.all'Old = Sock.all and then Received > 0,
            others => Sock.all = Sock.all'Old and then Received = 0 
        );

    procedure Tcp_Shutdown (
        Sock : in out Socket;
        How : unsigned;
        Error : out Error_T)
    with
        Depends => (
            Sock =>+ How,
            Error => (Sock, How)
        );
    
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

    procedure Tcp_Kill_Oldest_Connection (
        Sock : out Socket
    );

end Tcp_binding;
