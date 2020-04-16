pragma Restrictions(No_Tasking);

with Interfaces.C; use Interfaces.C;
with Socket_Binding; use Socket_Binding;
with Ip; use Ip;
with Error_H; use Error_H;

package Socket_Interface
with Spark_Mode
is

    pragma Unevaluated_Use_Of_Old (Allow);

    Socket_error : exception;

    type Port is range 0 .. 2 ** 16;
    type Buffer_Size is new Positive;

    type Socket_Type is (
        SOCKET_TYPE_UNUSED,
        SOCKET_TYPE_STREAM,
        SOCKET_TYPE_DGRAM,
        SOCKET_TYPE_RAW_IP,
        SOCKET_TYPE_RAW_ETH
    );

    for Socket_Type use (
        SOCKET_TYPE_UNUSED  => 0,
        SOCKET_TYPE_STREAM  => 1,
        SOCKET_TYPE_DGRAM   => 2,
        SOCKET_TYPE_RAW_IP  => 3,
        SOCKET_TYPE_RAW_ETH => 4
    );

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

    type Host_Resolver_Flags is array(Positive range <>) of Host_Resolver;

    procedure Get_Host_By_Name (
        Server_Name    : char_array; 
        Server_Ip_Addr : out IpAddr;
        Flags : Host_Resolver_Flags;
        Error : out Error_T)
    with
        Depends => (Server_Ip_Addr => (Server_Name, Flags),
                    Error => (Server_Name, Flags)),
        Post => 
            (if Error = NO_ERROR then 
                Server_Ip_Addr.length > 0);

    procedure Socket_Open (
        Sock:   out Socket_Struct;
        S_Type:     Socket_Type; 
        S_Protocol: Socket_Protocol)
    with
        Depends => (Sock => (S_Type, S_Protocol)),
        Post => Sock /= null
            and then Sock.S_Descriptor >= 0
            and then Sock.S_Type = Socket_Type'Enum_Rep(S_Type)
            and then Sock.S_Protocol = Socket_Protocol'Enum_Rep(S_Protocol)
            and then Sock.S_remoteIpAddr.length = 0;

    procedure Socket_Set_Timeout (
        Sock:    in out Socket_Struct; 
        Timeout: Systime;
        Error :  out Error_T)
    with
        Depends => (Sock => (Timeout, Sock),
                    Error => Timeout),
        Pre => Sock /= null,
        Contract_Cases => (Error = NO_ERROR => 
                                Sock /= null and then
                                Sock.all = Sock.all'Old'Update(S_Timeout => timeout),
                           others => True);
    
    procedure Socket_Connect (
        Sock : in out Socket_Struct;
        Remote_Ip_Addr : in  IpAddr;
        Remote_Port : in Sock_Port;
        Error : out Error_T)
    with
        Depends => (Sock => (Sock, Remote_Ip_Addr, Remote_Port),
                    Error => (Remote_Ip_Addr, Remote_Port)),
        Pre => Sock /= null
                and then Remote_Ip_Addr.length > 0,
        Contract_Cases => (
            Error = NO_ERROR =>
                Sock /= null and then 
                Sock.all = Sock.all'Old'Update(S_remoteIpAddr => Remote_Ip_Addr),
            others => True
        );

    procedure Socket_Send (
        Sock: in Socket_Struct;
        Data : in char_array;
        Error : out Error_T)
    with
        Depends => (Error => (Sock, Data)), 
        Pre => Sock /= null and then Sock.S_remoteIpAddr.length > 0,
        Contract_Cases => (
            Error = NO_ERROR => 
                Sock.all = Sock.all'Old,
            others => True
        );

    procedure Socket_Receive (
        Sock: in Socket_Struct;
        Buf : out char_array;
        Error : out Error_T)
    with
        Depends => (Buf => Sock, 
                    Error => Sock),
        Pre => Sock /= null and then Sock.S_remoteIpAddr.length > 0,
        Contract_Cases => (
            Error = NO_ERROR => Sock.all = Sock.all'Old and then Buf'Length > 0,
            Error = ERROR_END_OF_STREAM => Sock.all = Sock.all'Old and then Buf'Length = 0,
            others => Buf'Length = 0
        );

    procedure Socket_Shutdown (
        Sock  :     Socket_Struct;
        Error : out Error_T)
    with
        Depends => (Error => Sock),
        Pre => Sock /= null and then Sock.S_remoteIpAddr.length > 0,
        Contract_Cases => (
            Error = NO_ERROR => Sock.all = Sock.all'Old,
            others => True
        );

    procedure Socket_Close (Sock: in out Socket_Struct)
    with
        Pre => Sock /= null,
        Post => Sock = null;

    procedure Socket_Set_Tx_Buffer_Size (
        Sock : in out Socket_Struct;
        Size :        Buffer_Size;
        Error:    out Error_T)
    with
        Depends => (
            Sock => (Size, Sock),
            Error => (Size, Sock)
        ),
        Pre => (Sock /= null and then Sock.S_remoteIpAddr.length = 0),
        Contract_Cases => (
            Error = NO_ERROR => 
                Sock.all = Sock.all'Old'Update(txBufferSize => unsigned_long(Size)),
            others => Sock.all = Sock.all'Old
        );

    procedure Socket_Set_Rx_Buffer_Size (
        Sock : in out Socket_Struct;
        Size :        Buffer_Size;
        Error:    out Error_T)
    with
        Depends => (
            Sock => (Size, Sock),
            Error => (Size, Sock)
        ),
        Pre => Sock /= null and then Sock.S_remoteIpAddr.length = 0,
        Contract_Cases => (
            Error = NO_ERROR => 
                Sock.all = Sock.all'Old'Update(rxBufferSize => unsigned_long(Size)),
            others => Sock.all = Sock.all'Old
        );

    procedure Socket_Bind (
        Sock          : in out Socket_Struct;
        Local_Ip_Addr :        IpAddr;
        Local_Port    :        Sock_Port;
        Error         :    out Error_T)
    with
        Depends => (
            Sock => (Sock, Local_Ip_Addr, Local_Port),
            Error => (Sock, Local_Ip_Addr, Local_Port)
        ),
        Pre => Sock /= null
               and then Sock.S_remoteIpAddr.length = 0
               and then Sock.S_localIpAddr.length = 0;

    procedure Socket_Listen (
        Sock   :     Socket_Struct;
        Backlog:     Natural;
        Error  : out Error_T)
    with
        Depends => (
            Error => (Sock, Backlog)
        ),
        Pre => Sock /= null
               and then Sock.S_localIpAddr.length > 0;
    
    procedure Socket_Accept (
        Sock           :     Socket_Struct;
        Client_Ip_Addr : out IpAddr;
        Client_Port    : out Sock_Port;
        Client_Socket  : out Socket_Struct)
    with
        Depends => (
            Client_Ip_Addr => Sock,
            Client_Port => Sock,
            Client_Socket => Sock
        ),
        Pre => Sock /= null and then
               Sock.S_localIpAddr.length > 0;
        

end Socket_Interface;
