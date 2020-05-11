pragma Unevaluated_Use_Of_Old (Allow);
pragma Ada_2020;

with Interfaces.C; use Interfaces.C;
with Ip;           use Ip;
with Error_H;      use Error_H;
with Common_Type;  use Common_Type;
with Socket_Types; use Socket_Types;
with Net;          use Net;
with Tcp_binding, Udp_Binding;
use Tcp_binding, Udp_Binding;
with Tcp_Type;     use Tcp_Type;

package Socket_Interface with
   SPARK_Mode
is

   type Ttl_Type is mod 2**8;

   type Socket_Protocol is
     (SOCKET_IP_PROTO_ICMP,
      SOCKET_IP_PROTO_IGMP,
      SOCKET_IP_PROTO_TCP,
      SOCKET_IP_PROTO_UDP,
      SOCKET_IP_PROTO_ICMPV6);

   for Socket_Protocol use
     (SOCKET_IP_PROTO_ICMP   => 1,
      SOCKET_IP_PROTO_IGMP   => 2,
      SOCKET_IP_PROTO_TCP    => 6,
      SOCKET_IP_PROTO_UDP    => 17,
      SOCKET_IP_PROTO_ICMPV6 => 58);

   type Host_Resolver is mod 2 ** 6;

   HOST_NAME_RESOLVER_ANY   : Host_Resolver := 0;
   HOST_NAME_RESOLVER_DNS   : Host_Resolver := 1;
   HOST_NAME_RESOLVER_MDNS  : Host_Resolver := 2;
   HOST_NAME_RESOLVER_NBNS  : Host_Resolver := 4;
   HOST_NAME_RESOLVER_LLMNR : Host_Resolver := 8;
   HOST_TYPE_IPV4           : Host_Resolver := 16;
   HOST_TYPE_IPV6           : Host_Resolver := 32;

   type Socket_Shutdown_Flags is range 0 .. 2;
   SOCKET_SD_RECEIVE : Socket_Shutdown_Flags := 0;
   SOCKET_SD_SEND    : Socket_Shutdown_Flags := 1;
   SOCKET_SD_BOTH    : Socket_Shutdown_Flags := 2;

   procedure Get_Host_By_Name
     (Server_Name    :     char_array;
      Server_Ip_Addr : out IpAddr;
      Flags          :     Host_Resolver;
      Error          : out Error_T)
      with
        Depends =>
          (Server_Ip_Addr => (Server_Name, Flags),
           Error          => (Server_Name, Flags)),
        Post =>
          (if Error = NO_ERROR then 
             Is_Initialized_Ip(Server_Ip_Addr));

   procedure Socket_Open
     (Sock       : out Socket;
      S_Type     :     Socket_Type;
      S_Protocol :     Socket_Protocol)
      with
         Global =>
           (Input  => (Net_Mutex, Socket_Table),
            In_Out => Tcp_Dynamic_Port),
         Depends =>
           (Sock             => (S_Type, S_Protocol, Tcp_Dynamic_Port, Socket_Table),
            Tcp_Dynamic_Port => (S_Type, Tcp_Dynamic_Port),
            null             => Net_Mutex),
         Post =>
           (if Sock /= null then
              Sock.S_Descriptor >= 0 and then
              Sock.S_Type = Socket_Type'Enum_Rep (S_Type) and then
              not Is_Initialized_Ip(Sock.S_remoteIpAddr) and then
              not Is_Initialized_Ip(Sock.S_localIpAddr)),
         Contract_Cases =>
            (S_Type = SOCKET_TYPE_STREAM =>
               (if Sock /= null then
                  Sock.S_Protocol = SOCKET_IP_PROTO_TCP'Enum_Rep),
             S_Type = SOCKET_TYPE_DGRAM =>
               (if Sock /= null then
                  Sock.S_Protocol = SOCKET_IP_PROTO_UDP'Enum_Rep),
             others =>
               (if Sock /= null then
                  Sock.S_Protocol = Socket_Protocol'Enum_Rep (S_Protocol)));

   procedure Socket_Set_Timeout
      (Sock    : in out Not_Null_Socket;
       Timeout :        Systime)
      with
        Global =>
          (Input => Net_Mutex),
        Depends =>
          (Sock => (Timeout, Sock),
           null => Net_Mutex),
        Post =>
          Model(Sock) = Model(Sock)'Old'Update
             (S_Timeout => timeout);

   procedure Socket_Set_Ttl
      (Sock : in out Not_Null_Socket;
       Ttl  :        Ttl_Type)
      with
        Global =>
          (Input => Net_Mutex),
        Depends =>
          (Sock => (Ttl, Sock),
           null => Net_Mutex),
        Post =>
          Model(Sock) = Model(Sock)'Old'Update (
             S_TTL => unsigned_char (Ttl));

   procedure Socket_Set_Multicast_Ttl
      (Sock : in out Not_Null_Socket;
       Ttl  :        Ttl_Type)
      with
        Global =>
          (Input => Net_Mutex),
        Depends =>
          (Sock => (Ttl, Sock),
           null => Net_Mutex),
        Post =>
          Model(Sock) = Model(Sock)'Old'Update (
              S_Multicast_TTL => unsigned_char (Ttl));

   procedure Socket_Connect
      (Sock           : in out Not_Null_Socket;
       Remote_Ip_Addr : in     IpAddr;
       Remote_Port    : in     Port;
       Error          :    out Error_T)
      with
        Global =>
          (Input => Net_Mutex),
        Depends =>
          (Sock  => (Sock, Remote_Ip_Addr, Remote_Port),
           Error => (Sock, Remote_Ip_Addr, Remote_Port),
           null  => Net_Mutex),
        Pre =>
          Is_Initialized_Ip (Remote_Ip_Addr),
        Contract_Cases => (
          Sock.S_Type = SOCKET_TYPE_STREAM'Enum_Rep =>
               (if Error = NO_ERROR then
                  Model(Sock) = Model(Sock)'Old'Update
                     (S_remoteIpAddr => Remote_Ip_Addr,
                      S_Remote_Port  => Remote_Port)
               else
                  Model(Sock) = Model(Sock)'Old),
          Sock.S_Type = SOCKET_TYPE_DGRAM'Enum_Rep =>
               Error = NO_ERROR and then
               Model(Sock) = Model(Sock)'Old'Update
                     (S_remoteIpAddr => Remote_Ip_Addr,
                      S_Remote_Port  => Remote_Port),
          Sock.S_Type = SOCKET_TYPE_RAW_IP'Enum_Rep =>
             Error = NO_ERROR and then
             Model(Sock) = Model(Sock)'Old'Update
                (S_remoteIpAddr => Remote_Ip_Addr),
          others =>
             Model(Sock) = Model(Sock)'Old);

   procedure Socket_Send_To
      (Sock         : in out Not_Null_Socket;
       Dest_Ip_Addr :        IpAddr;
       Dest_Port    :        Port;
       Data         : in     char_array;
       Written      :    out Integer;
       Flags        :        unsigned;
       Error        :    out Error_T)
      with
        Global =>
          (Input => Net_Mutex),
        Depends =>
          (Error   => (Sock, Data, Flags),
           Sock    => (Sock, Flags),
           Written => (Sock, Data, Flags),
           null    => (Net_Mutex, Dest_Port, Dest_Ip_Addr)),
        Pre  =>
          Is_Initialized_Ip(Sock.S_remoteIpAddr),
        Post =>
          (if Error = NO_ERROR then
             Model(Sock) = Model(Sock)'Old and then
             Written > 0);

   procedure Socket_Send
      (Sock    : in out Not_Null_Socket;
       Data    : in     char_array;
       Written :    out Integer;
       Flags   :        Socket_Flags;
       Error   :    out Error_T)
      with
        Global =>
          (Input => Net_Mutex),
        Depends =>
          (Error   =>  (Sock, Data, Flags),
           Sock    =>+ Flags,
           Written =>  (Sock, Data, Flags),
           null    =>  Net_Mutex),
        Pre  =>
          Is_Initialized_Ip(Sock.S_remoteIpAddr),
        Post =>
          (if Error = NO_ERROR then 
             Model(Sock) = Model(Sock)'Old and then
             Written > 0);

   procedure Socket_Receive_Ex
      (Sock         : in out Not_Null_Socket;
       Src_Ip_Addr  :    out IpAddr;
       Src_Port     :    out Port;
       Dest_Ip_Addr :    out IpAddr;
       Data         :    out char_array;
       Received     :    out unsigned;
       Flags        :        Socket_Flags;
       Error        :    out Error_T)
      with
        Global =>
          (Input => Net_Mutex),
        Depends =>
          (Sock         =>  (Sock, Flags),
           Data         =>+ (Sock, Flags),
           Received     =>  (Sock, Flags),
           Src_Ip_Addr  =>  (Sock, Flags),
           Src_Port     =>  (Sock, Flags),
           Dest_Ip_Addr =>  (Sock, Flags),
           Error        =>  (Sock, Flags),
           null         =>  Net_Mutex),
        Pre =>
          Is_Initialized_Ip(Sock.S_remoteIpAddr) and then
          Data'Last >= Data'First,
        Contract_Cases =>
          (Sock.S_Type = SOCKET_TYPE_STREAM'Enum_Rep =>
               (if Error = NO_ERROR then
                  Model(Sock) = Model(Sock)'Old and then
                  Received > 0
                elsif Error = ERROR_END_OF_STREAM then
                  Model(Sock) = Model(Sock)'Old and then
                  Received = 0),
           others =>
               Error = ERROR_INVALID_SOCKET and then
               Model(Sock) = Model(Sock)'Old and then
               Received = 0);

   procedure Socket_Receive
      (Sock     : in out Not_Null_Socket;
       Data     :    out char_array;
       Received :    out unsigned;
       Flags    :        Socket_Flags;
       Error    :    out Error_T)
      with
        Global =>
          (Input => Net_Mutex),
        Depends =>
          (Sock     =>  (Sock, Flags),
           Data     =>+ (Sock, Flags),
           Error    =>  (Sock, Flags),
           Received =>  (Sock, Flags),
           null     =>  Net_Mutex),
        Pre =>
          Is_Initialized_Ip(Sock.S_remoteIpAddr) and then
          Data'Last >= Data'First,
        Contract_Cases =>
          (Sock.S_Type = SOCKET_TYPE_STREAM'Enum_Rep =>
             (if Error = NO_ERROR then
                Model(Sock) = Model(Sock)'Old and then
                Received > 0
             elsif Error = ERROR_END_OF_STREAM then
                Model(Sock) = Model(Sock)'Old and then
                Received = 0),
           others =>
             Error = ERROR_INVALID_SOCKET and then
             Model(Sock) = Model(Sock)'Old and then
             Received = 0);

   procedure Socket_Shutdown
      (Sock  : in out Not_Null_Socket;
       How   :        Socket_Shutdown_Flags;
       Error :    out Error_T)
      with
        Global =>
          (Input => Net_Mutex),
        Depends =>
          (Sock  => (Sock, How),
           Error => (Sock, How),
           null  => Net_Mutex),
        Pre =>
          Sock.S_Type = SOCKET_TYPE_STREAM'Enum_Rep and then
          Is_Initialized_Ip(Sock.S_remoteIpAddr),
        Post =>
          (if Error = NO_ERROR then
             Model(Sock) = Model(Sock)'Old);

   procedure Socket_Close
      (Sock : in out Not_Null_Socket)
      with
        Global  => (Input => Net_Mutex),
        Depends => (Sock => Sock, null => Net_Mutex),
        Post    => Sock.S_Type = SOCKET_TYPE_UNUSED'Enum_Rep;

   procedure Socket_Set_Tx_Buffer_Size
      (Sock : in out Not_Null_Socket;
       Size :        Tx_Buffer_Size)
      with
        Depends => (Sock => (Size, Sock)),
        Pre => Sock.S_Type = SOCKET_TYPE_STREAM'Enum_Rep and then
               not Is_Initialized_Ip(Sock.S_remoteIpAddr) and then
               Sock.State = TCP_STATE_CLOSED,
        Post =>
          Model(Sock) = Model(Sock)'Old'Update
               (S_Tx_Buffer_Size => Size);

   procedure Socket_Set_Rx_Buffer_Size
      (Sock : in out Not_Null_Socket;
       Size :        Rx_Buffer_Size)
      with
        Depends => (Sock => (Size, Sock)),
        Pre =>
          Sock.S_Type = SOCKET_TYPE_STREAM'Enum_Rep and then
          not Is_Initialized_Ip (Sock.S_remoteIpAddr) and then
          Sock.State = TCP_STATE_CLOSED,
        Post =>
            Model(Sock) = Model(Sock)'Old'Update
                  (S_Rx_Buffer_Size => Size);

   procedure Socket_Bind
      (Sock          : in out Not_Null_Socket;
       Local_Ip_Addr :        IpAddr;
       Local_Port    :        Port)
      with
       Depends => (Sock => (Sock, Local_Ip_Addr, Local_Port)),
       Pre =>
         not Is_Initialized_Ip(Sock.S_remoteIpAddr) and then
         not Is_Initialized_Ip(Sock.S_localIpAddr) and then
         Is_Initialized_Ip(Local_Ip_Addr) and then
         (Sock.S_Type = SOCKET_TYPE_STREAM'Enum_Rep or else
          Sock.S_Type = SOCKET_TYPE_DGRAM'Enum_Rep),
       Post =>
         Model(Sock) = Model(Sock)'Old'Update
           (S_localIpAddr => Local_Ip_Addr,
            S_Local_Port  => Local_Port);

   procedure Socket_Listen
      (Sock    : in out Not_Null_Socket;
       Backlog :        Natural;
       Error   :    out Error_T)
      with
        Global => Net_Mutex,
        Depends =>
          (Sock  =>+ Backlog,
           Error =>  (Sock, Backlog),
           null =>Net_Mutex),
        Pre =>
          Sock.S_Type = SOCKET_TYPE_STREAM'Enum_Rep and then
          Is_Initialized_Ip(Sock.S_localIpAddr) and then
          not Is_Initialized_Ip(Sock.S_remoteIpAddr),
        Post =>
          Model(Sock) = Model(Sock)'Old;

   procedure Socket_Accept
      (Sock           : in out Not_Null_Socket;
       Client_Ip_Addr :    out IpAddr;
       Client_Port    :    out Port;
       Client_Socket  :    out Socket)
      with
        Depends =>
          (Sock           => Sock,
           Client_Ip_Addr => Sock,
           Client_Port    => Sock,
           Client_Socket  => Sock),
       Pre => Sock.S_Type = SOCKET_TYPE_STREAM'Enum_Rep and then
              Is_Initialized_Ip(Sock.S_localIpAddr) and then
              not Is_Initialized_Ip(Sock.S_remoteIpAddr),
       Post => Model(Sock) = Model(Sock)'Old and then
               Is_Initialized_Ip(Client_Ip_Addr) and then
               Client_Port > 0 and then
               Client_Socket /= null and then
               Client_Socket.S_Type = Sock.S_Type and then
               Client_Socket.S_Protocol = Sock.S_Protocol and then
               Client_Socket.S_Local_Port = Sock.S_Local_Port and then
               Client_Socket.S_localIpAddr = Sock.S_localIpAddr and then
               Client_Socket.S_remoteIpAddr = Client_Ip_Addr and then
               Client_Socket.S_Remote_Port = Client_Port;

end Socket_Interface;
