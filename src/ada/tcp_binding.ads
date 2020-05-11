pragma Ada_2020;
pragma Unevaluated_Use_Of_Old (Allow);

with Common_Type;  use Common_Type;
with Error_H;      use Error_H;
with Interfaces.C; use Interfaces.C;
with Ip;           use Ip;
with Net;          use Net;
with Socket_Types; use Socket_Types;
with Tcp_Type;     use Tcp_Type;

package Tcp_Binding
  with SPARK_Mode
is
    -- Ephemeral ports are used for dynamic port assignment
    Tcp_Dynamic_Port : Port;

    function Tcp_Init return Error_T
      with
        Import => True,
        Convention => C,
        External_Name => "tcpInit";

    procedure Tcp_Get_Dynamic_Port
      (P : out Port)
      with
        Global =>
          (In_Out => Tcp_Dynamic_Port),
        Depends =>
          (P                => Tcp_Dynamic_Port,
           Tcp_Dynamic_Port => Tcp_Dynamic_Port),
        Post =>
          P in SOCKET_EPHEMERAL_PORT_MIN .. SOCKET_EPHEMERAL_PORT_MAX and then
          Tcp_Dynamic_Port in SOCKET_EPHEMERAL_PORT_MIN .. SOCKET_EPHEMERAL_PORT_MAX;

    procedure Tcp_Connect
      (Sock           : in out Not_Null_Socket;
       Remote_Ip_Addr :        IpAddr;
       Remote_Port    :        Port;
       Error          :    out Error_T)
      with
        Depends =>
          (Sock  =>+ (Remote_Ip_Addr, Remote_Port),
           Error => (Sock, Remote_Port, Remote_Ip_Addr)),
        Post =>
          (if Error = No_ERROR then
             Model(Sock) = Model(Sock)'Old'Update(
               S_RemoteIpAddr => Remote_Ip_Addr,
               S_Remote_Port  => Remote_Port)
           else
             Model(Sock) = Model(Sock)'Old);

    procedure Tcp_Listen
      (Sock    : in out Not_Null_Socket;
       Backlog :        Unsigned;
       Error   :    out Error_T)
      with
        Depends =>
          (Sock  =>+ Backlog,
           Error => (Sock, Backlog)),
        Post =>
          Model(Sock) = Model(Sock)'Old;

    procedure Tcp_Accept
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
        Post =>
          Client_Ip_Addr.Length > 0 and then
          Client_Port > 0 and then
          Client_Socket /= null and then
          Client_Socket.S_RemoteIpAddr = Client_Ip_Addr and then
          Client_Socket.S_Remote_Port = Client_Port and then
          Client_Socket.S_Protocol = Sock.S_Protocol and then
          Client_Socket.S_Local_Port = Sock.S_Local_Port and then
          Client_Socket.S_Type = Sock.S_Type and then
          Client_Socket.S_LocalIpAddr = Sock.S_LocalIpAddr and then
          Model(Sock) = Model(Sock)'Old and then
          -- TCP STATE Condition
          Sock.State = TCP_STATE_LISTEN;
   
    procedure Tcp_Send
      (Sock    : in out Not_Null_Socket;
       Data    :        Char_Array;
       Written :    out Integer;
       Flags   :        Unsigned;
       Error   :    out Error_T)
      with
        Depends =>
          (Sock    => (Sock, Flags),
           Written => (Sock, Data, Flags),
           Error   => (Sock, Data, Flags)),
        Post =>
          Model(Sock) = Model(Sock)'Old and then
          (if Error = No_ERROR then Written > 0);

    procedure Tcp_Receive
      (Sock     : in out Not_Null_Socket;
       Data     :    out Char_Array;
       Received :    out Unsigned;
       Flags    :        Unsigned;
       Error    :    out Error_T)
      with
        Depends =>
          (Error    =>  (Sock, Flags),
           Sock     =>+ Flags,
           Data     =>  (Sock, Flags),
           Received =>  (SoCk, Flags)),
        Pre =>
          Sock.S_Type = SOCKET_TYPE_STREAM'Enum_Rep and then
          Sock.S_RemoteIpAddr.Length /= 0 and then
          Data'Last >= Data'First,
        Post =>
          Model(Sock) = Model(Sock)'Old and then
          (if Error = NO_ERROR then
             Received > 0
           elsif Error = ERROR_END_OF_STREAM then
             Received = 0);

    procedure Tcp_Shutdown
      (Sock  : in out Not_Null_Socket;
       How   :        Unsigned;
       Error :    out Error_T)
      with
        Depends =>
          (Sock  =>+ How,
           Error =>  (Sock, How)),
        Post =>
          Model(Sock) = Model(Sock)'Old;
   
    procedure Tcp_Abort
      (Sock  : in out Not_Null_Socket;
       Error :    out Error_T)
      with
        Depends => (Sock => Sock,
                    Error => Sock),
        Post => -- @TODO
                -- In a first approximation, it'll work.
                -- I forget the 2MSL timer...
                Sock.S_Type = SOCKET_TYPE_UNUSED'Enum_Rep;

    procedure Tcp_Kill_Oldest_Connection
      (Sock : out Socket)
      with
        Depends => (Sock => null),
        Post =>
           (if Sock /= null then
              Sock.S_Type = SOCKET_TYPE_UNUSED'Enum_Rep);

    procedure Tcp_Get_State
      (Sock  : in     Not_Null_Socket;
       State :    out Tcp_State)
      with
        Global  => (Input => Net_Mutex),
        Depends =>
          (State => Sock,
           null  => Net_Mutex),
        Post =>
          State = Sock.State and then
          Model(Sock) = Model(Sock)'Old;

end Tcp_binding;
