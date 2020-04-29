pragma Restrictions(No_Tasking);

with Interfaces.C; use Interfaces.C;
with Socket_Binding; use Socket_Binding;
with Ip; use Ip;
with Error_H; use Error_H;
with Common_Type; use Common_Type;
with Socket_Types; use Socket_Types;
with Net; use Net;
with Tcp_Binding, Udp_Binding; use Tcp_binding, Udp_Binding;

package Socket_Interface 
    with SPARK_MODE
is
    pragma Unevaluated_Use_Of_Old (Allow);

    Socket_error : exception;

    type Buffer_Size is new Positive;
    type Ttl_Type is mod 2 ** 8;

    type Socket_Protocol is (
        SOCKET_IP_PROTO_ICMP,
        SOCKET_IP_PROTO_IGMP,
        SOCKET_IP_PROTO_TCP,
        SOCKET_IP_PROTO_UDP,
        SOCKET_IP_PROTO_ICMPV6
    );

    for Socket_Protocol use (
        SOCKET_IP_PROTO_ICMP   => 1,
        SOCKET_IP_PROTO_IGMP   => 2,
        SOCKET_IP_PROTO_TCP    => 6,
        SOCKET_IP_PROTO_UDP    => 17,
        SOCKET_IP_PROTO_ICMPV6 => 58
    );

    type Host_Resolver is (
        HOST_NAME_RESOLVER_ANY,
        HOST_NAME_RESOLVER_DNS,
        HOST_NAME_RESOLVER_MDNS,
        HOST_NAME_RESOLVER_NBNS,
        HOST_NAME_RESOLVER_LLMNR,
        HOST_TYPE_IPV4,
        HOST_TYPE_IPV6
    );

    for Host_Resolver use (
        HOST_NAME_RESOLVER_ANY   => 0,
        HOST_NAME_RESOLVER_DNS   => 1,
        HOST_NAME_RESOLVER_MDNS  => 2,
        HOST_NAME_RESOLVER_NBNS  => 4,
        HOST_NAME_RESOLVER_LLMNR => 8,
        HOST_TYPE_IPV4           => 16,
        HOST_TYPE_IPV6           => 32
    );

    type Socket_Shutdown_Flags is (
        SOCKET_SD_RECEIVE,
        SOCKET_SD_SEND,
        SOCKET_SD_BOTH
    );

    for Socket_Shutdown_Flags use (
        SOCKET_SD_RECEIVE => 0,
        SOCKET_SD_SEND    => 1,
        SOCKET_SD_BOTH    => 2
    );

    type Host_Resolver_Flags is array(Positive range <>) of Host_Resolver;

    procedure Get_Host_By_Name (
        Server_Name    : char_array; 
        Server_Ip_Addr : out IpAddr;
        Flags : Host_Resolver_Flags;
        Error : out Error_T)
    with
        Depends => (Server_Ip_Addr => (Server_Name, Flags),
                    Error => (Server_Name, Flags)),
        Post => (
            if Error = NO_ERROR then 
                Server_Ip_Addr.length > 0
        );

    procedure Socket_Open (
        Sock:   out Socket;
        S_Type:     Socket_Type; 
        S_Protocol: Socket_Protocol)
    with
        Global => (Input => (Net_Mutex, Socket_Table),
                   In_Out => Tcp_Dynamic_Port),
        Depends => (Sock => (S_Type, S_Protocol, Tcp_Dynamic_Port, Socket_Table),
                    Tcp_Dynamic_Port => (S_Type, Tcp_Dynamic_Port),
                    null => Net_Mutex),
        Post => 
            (if Sock /= null then
                Sock.S_Descriptor >= 0
                and then Sock.S_Type = Socket_Type'Enum_Rep(S_Type)
                and then Sock.S_Protocol = Socket_Protocol'Enum_Rep(S_Protocol)
                and then Sock.S_remoteIpAddr.length = 0
                and then Sock.S_localIpAddr.length = 0
                and then Sock.S_remoteIpAddr.length = 0);

    procedure Socket_Set_Timeout (
        Sock:    in out Socket; 
        Timeout: Systime)
    with
        Global => (Input => Net_Mutex),
        Depends => (Sock => (Timeout, Sock),
                    null => Net_Mutex),
        Pre => Sock /= null,
        Post => Sock /= null and then
                Sock.all = Sock.all'Old'Update(S_Timeout => timeout);

    procedure Socket_Set_Ttl (
        Sock : in out Socket;
        Ttl  :        Ttl_Type
    )
    with
        Global => (Input => Net_Mutex),
        Depends => (Sock => (Ttl, Sock),
                    null => Net_Mutex),
        Pre => Sock /= null,
        Post => Sock /= null and then
                Sock.all = Sock.all'Old'Update(S_TTL => unsigned_char(Ttl));

    procedure Socket_Set_Multicast_Ttl (
        Sock : in out Socket;
        Ttl  :        Ttl_Type
    )
    with
        Global => (Input => Net_Mutex),
        Depends => (Sock => (Ttl, Sock),
                    null => Net_Mutex),
        Pre => Sock /= null,
        Post => Sock /= null and then
                Sock.all = Sock.all'Old'Update(S_Multicast_TTL => unsigned_char(Ttl));
    
    procedure Socket_Connect (
        Sock : in out Socket;
        Remote_Ip_Addr : in  IpAddr;
        Remote_Port : in Port;
        Error : out Error_T)
    with
        Global => (Input => Net_Mutex),
        Depends => (Sock => (Sock, Remote_Ip_Addr, Remote_Port),
                    Error => (Remote_Ip_Addr, Remote_Port),
                    null => Net_Mutex),
        Pre => Sock /= null
                and then Remote_Ip_Addr.length > 0,
        Contract_Cases => (
            Error = NO_ERROR =>
                Sock /= null and then 
                Sock.all = Sock.all'Old'Update(S_remoteIpAddr => Remote_Ip_Addr),
            others => True
        );

    procedure Socket_Send (
        Sock: in Socket;
        Data : in char_array;
        Written : out Integer;
        Error : out Error_T)
    with
        Global => (Input => Net_Mutex),
        Depends => (Error => (Sock, Data),
                    Written => (Sock, Data),
                    null => Net_Mutex),
        Pre => Sock /= null and then Sock.S_remoteIpAddr.length > 0,
        Contract_Cases => (
            Error = NO_ERROR => 
                Sock.all = Sock.all'Old,
            others => True
        );

    procedure Socket_Receive (
        Sock: in Socket;
        Buf : out char_array;
        Error : out Error_T)
    with
        Global => (Input => Net_Mutex),
        Depends => (Buf => Sock, 
                    Error => Sock,
                    null => Net_Mutex),
        Pre => Sock /= null and then Sock.S_remoteIpAddr.length > 0,
        Contract_Cases => (
            Error = NO_ERROR => Sock.all = Sock.all'Old and then Buf'Length > 0,
            Error = ERROR_END_OF_STREAM => Sock.all = Sock.all'Old and then Buf'Length = 0,
            others => Buf'Length = 0
        );

    procedure Socket_Shutdown (
        Sock  :     Socket;
        How   :     Socket_Shutdown_Flags;
        Error : out Error_T)
    with
        Global => (Input => Net_Mutex),
        Depends => (Error => (Sock, How),
                    null => Net_Mutex),
        Pre => Sock /= null and then 
               Sock.S_remoteIpAddr.length > 0,
        Contract_Cases => (
            Error = NO_ERROR => Sock.all = Sock.all'Old,
            others => True
        );

    procedure Socket_Close (Sock: in out Socket)
    with
        Pre => Sock /= null,
        Post => Sock = null;

    procedure Socket_Set_Tx_Buffer_Size (
        Sock : in out Socket;
        Size :        Buffer_Size)
    with
        Depends => (
            Sock => (Size, Sock)
        ),
        Pre => Sock /= null 
               and then Sock.S_Type = Socket_Type'Enum_Rep(SOCKET_TYPE_STREAM)
               and then Sock.S_remoteIpAddr.length = 0 -- this condition is to represent that the connexion is closed
               and then Size > 1 and then Size < 22880, -- TCP_MAX_TX_BUFFER_SIZE
        Post => 
            Sock.all = Sock.all'Old'Update(txBufferSize => unsigned_long(Size));

    procedure Socket_Set_Rx_Buffer_Size (
        Sock : in out Socket;
        Size :        Buffer_Size)
    with
        Depends => (
            Sock => (Size, Sock)
        ),
        Pre => Sock /= null 
               and then Sock.S_Type = Socket_Type'Enum_Rep(SOCKET_TYPE_STREAM)
               and then Sock.S_remoteIpAddr.length = 0 -- this condition is to represent that the connexion is closed
               and then Size > 1 and then Size < 22880, -- TCP_MAX_RX_BUFFER_SIZE
        Post =>
            Sock.all = Sock.all'Old'Update(rxBufferSize => unsigned_long(Size));

    procedure Socket_Bind (
        Sock          : in out Socket;
        Local_Ip_Addr :        IpAddr;
        Local_Port    :        Port)
    with
        Depends => (
            Sock => (Sock, Local_Ip_Addr, Local_Port)
        ),
        Pre => Sock /= null
               and then Sock.S_remoteIpAddr.length = 0
               and then Sock.S_localIpAddr.length = 0
               and then (Sock.S_Type = Socket_Type'Enum_Rep(SOCKET_TYPE_STREAM)
                         or else Sock.S_Type = Socket_Type'Enum_Rep(SOCKET_TYPE_DGRAM)),
        Post => Sock /= null and then
                Sock.all = Sock.all'Old'Update(
                    S_localIpAddr => Local_Ip_Addr,
                    S_Local_Port => Local_Port
                );

    procedure Socket_Listen (
        Sock   :     Socket;
        Backlog:     Natural;
        Error  : out Error_T)
    with
        Depends => (
            Error => (Sock, Backlog)
        ),
        Pre => Sock /= null
               and then Sock.S_Type = Socket_Type'Enum_Rep(SOCKET_TYPE_STREAM)
               and then Sock.S_localIpAddr.length > 0
               and then Sock.S_remoteIpAddr.length = 0,
        Post => Sock.all = Sock.all'Old;
    
    procedure Socket_Accept (
        Sock           :     Socket;
        Client_Ip_Addr : out IpAddr;
        Client_Port    : out Port;
        Client_Socket  : out Socket)
    with
        Depends => (
            Client_Ip_Addr => Sock,
            Client_Port => Sock,
            Client_Socket => Sock
        ),
        Pre => Sock /= null and then
               Sock.S_Type = Socket_Type'Enum_Rep(SOCKET_TYPE_STREAM) and then
               Sock.S_localIpAddr.length > 0 and then
               Sock.S_remoteIpAddr.length = 0,
        Post => Sock.all = Sock.all'Old
                and then Client_Ip_Addr.length > 0
                and then Client_Port > 0
                -- TODO: Maybe the socket can be null. Check
                and then Client_Socket /= null
                and then Client_Socket.S_Type = Sock.S_Type
                and then Client_Socket.S_Protocol = Sock.S_Protocol
                and then Client_Socket.S_Local_Port = Sock.S_Local_Port
                and then Client_Socket.S_localIpAddr = Sock.S_localIpAddr
                and then Client_Socket.S_remoteIpAddr = Client_Ip_Addr
                and then Client_Socket.S_Remote_Port = Client_Port;
        

end Socket_Interface;
