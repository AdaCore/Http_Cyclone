with Interfaces.C; use Interfaces.C;
with Socket_Binding; use Socket_Binding;
with Ip; use Ip;

package Socket_Interface
with Spark_Mode
is

    Socket_error : exception;

    type Port is range 0 .. 2 ** 16;

--    type Socket is 
--       record
--          S_Descriptor: Sock_Descriptor;
--          S_Type: Sock_Type;
--          S_Protocol: Sock_Protocol;
--          S_NetInterface: access Net_Interface;
--          S_localIpAddr: IpAddr;
--          S_Local_Port: Sock_Port;
--          S_remoteIpAddr: IpAddr;
--          S_Remote_Port: Sock_Port;
--          S_Timeout: Compiler_Port.Systime;
--          S_TTL: unsigned_char;
--          S_Multicast_TTL: unsigned_char;
--          S_errnoCode: int;
--          S_event: OsEvent;
--          S_Event_Mask: unsigned;
--          S_Event_Flags: unsigned;
--          userEvent: access OsEvent;
         
--          -- TCP specific variables
--          State: Tcp_State;
--          owned_Flag: Bool;
--          closed_Flag: Bool;
--          reset_Flag: Bool;
         
--          smss: unsigned_short;
--          rmss: unsigned_short;
--          iss: unsigned_long;
--          irs: unsigned_long;
         
--          sndUna: unsigned_long;
--          sndNxt: unsigned_long;
--          sndUser: unsigned_short;
--          sndWnd: unsigned_short;
--          maxSndWnd: unsigned_short;
--          sndWl1: unsigned_long;
--          sndWl2: unsigned_long;
         
--          rcvNxt: unsigned_long;
--          rcvUser: unsigned_short;
--          rcvWnd: unsigned_short;
         
--          rttBusy: Bool;
--          rttSeqNum: unsigned_long;
--          rettStartTime: Systime;
--          srtt: Systime;
--          rttvar: Systime;
--          rto: Systime;
         
--          congestState: TCP_Congest_State;
--          cwnd: unsigned_short;
--          ssthresh: unsigned_short;
--          dupAckCount: unsigned;
--          n: unsigned;
--          recover: unsigned_long;
         
--          txBuffer: Tcp_Tx_Buffer;
--          txBufferSize: unsigned_long;
--          rxBuffer: Tcp_Rx_Buffer;
--          rxBufferSize: unsigned_long;
         
--          retransmitQueue: access TcpQueueItem;
--          retransmitTimer: Tcp_Timer;
--          retransmitCount: unsigned;
         
--          -- TODO: Not good type. Just used to denote a pointer
--          synQueue: access TcpQueueItem;
--          synQueueSize: unsigned;
         
--          wndProbeCount: unsigned;
--          wndProbeInterval: Systime;
         
--          persistTimer: Tcp_Timer;
--          overrideTimer: Tcp_Timer;
--          finWait2Timer: Tcp_Timer;
--          timeWaitTimer: Tcp_Timer;
         
--          sackPermitted: Bool;
--          sackBlock: SackBlockArray;
--          sackBlockCount: unsigned;
         
--          -- TODO: should be socketQueueItem here
--          receiveQueue: access TcpQueueItem;
         
--       end record;

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

    procedure Get_Host_By_Name (
        Server_Name    : char_array; 
        Server_Ip_Addr : out IpAddr);

    procedure Socket_Open (
        Sock: in out Socket_Struct;
        S_Type:     Socket_Type; 
        S_Protocol: Socket_Protocol);

    procedure Socket_Set_Timeout (
        sock:    Socket_Struct; 
        timeout: Systime);
    
    procedure Socket_Connect (
        Sock :           Socket_Struct;
        Remote_Ip_Addr : IpAddr;
        Remote_Port :    Sock_Port);

    procedure Socket_Send (
        Sock: Socket_Struct;
        Data : char_array);

    function Socket_Receive (
        Sock: Socket_Struct;
        Buf : out char_array)
    return Integer
    with 
        Pre => Buf'Length > 0;

    procedure Socket_Shutdown (
        Sock: Socket_Struct);

    procedure Socket_Close (
        Sock: Socket_Struct);

end Socket_Interface;