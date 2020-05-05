with Error_H; use Error_H;
with Interfaces.C; use Interfaces.C;
with Ip; use Ip;
with Tcp_Type; use Tcp_Type;
with Common_Type; use Common_Type;
with Socket_Types; use Socket_Types;

package Tcp_binding 
    with SPARK_Mode
is
    pragma Unevaluated_Use_Of_Old (Allow);

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
        ),
        Pre => Sock /= null,
        Post => Sock /= null and then
                (if Error = No_ERROR then
                    Sock.all = Sock.all'Old'Update
                        (S_remoteIpAddr => Remote_Ip_Addr,
                         S_Remote_Port => Remote_Port)
                else
                    Sock.all = Sock.all'Old);

    procedure Tcp_Listen (
            Sock : in out Socket;
            Backlog : unsigned;
            Error : out Error_T)
    with
        Depends => (
            Sock =>+ Backlog,
            Error => (Sock, Backlog)
        ),
        Pre => Sock /= null,
        Post => Sock /= null and then
                Sock.all = Sock.all'Old;

    procedure Tcp_Accept (
            Sock : in out Socket;
            Client_Ip_Addr : out IpAddr;
            Client_Port : out Port;
            Client_Socket : out Socket)
    with
        Depends => (
            Sock => Sock,
            Client_Ip_Addr => Sock,
            Client_Port => Sock,
            Client_Socket => Sock
        ),
        Pre => Sock /= null,
        Post => (Sock /= null and then
                Client_Ip_Addr.length > 0 and then
                Client_Port > 0 and then
                Client_Socket /= null and then
                Client_Socket.S_remoteIpAddr = Client_Ip_Addr and then
                Client_Socket.S_Remote_Port = Client_Port and then
                Client_Socket.S_Protocol = Sock.S_Protocol and then
                Client_Socket.S_Local_Port = Sock.S_Local_Port and then
                Client_Socket.S_Type = Sock.S_Type and then
                Client_Socket.S_localIpAddr = Sock.S_localIpAddr and then
                Sock.all = Sock.all'Old);
    
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
        ),
        Pre => Sock /= null,
        Post => Sock /= null and then
                Sock.all = Sock.all'Old;

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
        Pre => Sock /= null and then Sock.S_remoteIpAddr.length /= 0
                and then Data'Length > 0,
        Post => Sock /= null and then
                    Sock.all = Sock.all'Old and then
                    (if Error = NO_ERROR then
                        Received > 0
                    elsif Error = ERROR_END_OF_STREAM then
                        Received = 0);

    procedure Tcp_Shutdown (
        Sock : in out Socket;
        How : unsigned;
        Error : out Error_T)
    with
        Depends => (
            Sock =>+ How,
            Error => (Sock, How)
        ),
        Pre => Sock /= null,
        Post => Sock /= null and then
                Sock.all = Sock.all'Old;
    
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
