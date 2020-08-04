with Common_Type;  use Common_Type;
with Interfaces.C; use Interfaces.C;
with Ip;           use Ip;
with Net_Misc;     use Net_Misc;
with Os_Types;     use Os_Types;
with System;
with Tcp_Type;     use Tcp_Type;

package Socket_Types
   with SPARK_Mode
is

   type SackBlockArray is array (0 .. 3) of Tcp_Sack_Block;

   ------------------
   -- Socket_Event --
   ------------------

   type Socket_Event is mod 2 ** 10
      with Size => int'Size;
   -- for Socket_Event'Size use unsigned'Size;

   SOCKET_EVENT_TIMEOUT     : constant Socket_Event := 000;
   SOCKET_EVENT_CONNECTED   : constant Socket_Event := 001;
   SOCKET_EVENT_CLOSED      : constant Socket_Event := 002;
   SOCKET_EVENT_TX_READY    : constant Socket_Event := 004;
   SOCKET_EVENT_TX_DONE     : constant Socket_Event := 008;
   SOCKET_EVENT_TX_ACKED    : constant Socket_Event := 016;
   SOCKET_EVENT_TX_SHUTDOWN : constant Socket_Event := 032;
   SOCKET_EVENT_RX_READY    : constant Socket_Event := 064;
   SOCKET_EVENT_RX_SHUTDOWN : constant Socket_Event := 128;
   SOCKET_EVENT_LINK_UP     : constant Socket_Event := 256;
   SOCKET_EVENT_LINK_DOWN   : constant Socket_Event := 512;

   ---------------------------
   -- Socket_Shutdown_Flags --
   ---------------------------

   type Socket_Shutdown_Flags is
      (SOCKET_SD_RECEIVE,
       SOCKET_SD_SEND,
       SOCKET_SD_BOTH);

   -----------------
   -- Socket_Type --
   -----------------

   type Socket_Type is
     (SOCKET_TYPE_UNUSED,
      SOCKET_TYPE_STREAM,
      SOCKET_TYPE_DGRAM,
      SOCKET_TYPE_RAW_IP,
      SOCKET_TYPE_RAW_ETH);

   for Socket_Type'Size use int'Size;

   for Socket_Type use
     (SOCKET_TYPE_UNUSED  => 0,
      SOCKET_TYPE_STREAM  => 1,
      SOCKET_TYPE_DGRAM   => 2,
      SOCKET_TYPE_RAW_IP  => 3,
      SOCKET_TYPE_RAW_ETH => 4);

   ----------------------
   -- Socket_Porotocol --
   ----------------------

   type Socket_Protocol is
     (SOCKET_IP_PROTO_ICMP,
      SOCKET_IP_PROTO_IGMP,
      SOCKET_IP_PROTO_TCP,
      SOCKET_IP_PROTO_UDP,
      SOCKET_IP_PROTO_ICMPV6);

   for Socket_Protocol'Size use int'Size;

   for Socket_Protocol use
     (SOCKET_IP_PROTO_ICMP   => 1,
      SOCKET_IP_PROTO_IGMP   => 2,
      SOCKET_IP_PROTO_TCP    => 6,
      SOCKET_IP_PROTO_UDP    => 17,
      SOCKET_IP_PROTO_ICMPV6 => 58);
   
   ------------------------
   -- Receive queue item --
   ------------------------

   type Socket_Queue_Item;
   type Socket_Queue_Item_Acc is access Socket_Queue_Item;
   type Socket_Queue_Item is record
      Next           : Socket_Queue_Item_Acc;
      Src_Ip_Addr    : IpAddr;
      Src_Port       : Port;
      Dest_Ip_Addr   : IpAddr;
      Buffer         : System.Address;
      Offset         : size_t;
      Ancillary      : Net_Ancillary_Data;
   end record;

   -----------------------
   -- Socket Definition --
   -----------------------

   type Socket_Struct is record
      S_Descriptor    : Sock_Descriptor;
      S_Type          : Socket_Type;
      S_Protocol      : Socket_Protocol;
      S_Net_Interface : System.Address;
      S_localIpAddr   : IpAddr;
      S_Local_Port    : Port;
      S_Remote_Ip_Addr  : IpAddr;
      S_Remote_Port   : Port;
      S_Timeout       : Systime;
      S_TTL           : unsigned_char;
      S_Multicast_TTL : unsigned_char;
      S_Errno_Code    : int;
      S_Event         : Os_Event;
      S_Event_Mask    : Socket_Event;
      S_Event_Flags   : Socket_Event;
      S_User_Event    : Os_Event_Acc;

      -- TCP specific variables
      State       : Tcp_State;
      owned_Flag  : Bool;
      closed_Flag : Bool;
      reset_Flag  : Bool;

      smss : unsigned_short;
      rmss : unsigned_short;
      iss  : unsigned;
      irs  : unsigned;

      sndUna    : unsigned;
      sndNxt    : unsigned;
      sndUser   : unsigned_short;
      sndWnd    : unsigned_short;
      maxSndWnd : unsigned_short;
      sndWl1    : unsigned;
      sndWl2    : unsigned;

      rcvNxt  : unsigned;
      rcvUser : unsigned_short;
      rcvWnd  : unsigned_short;

      rttBusy       : Bool;
      rttSeqNum     : unsigned;
      rettStartTime : Systime;
      srtt          : Systime;
      rttvar        : Systime;
      rto           : Systime;

      congestState : TCP_Congest_State;
      cwnd         : unsigned_short;
      ssthresh     : unsigned_short;
      dupAckCount  : unsigned;
      n            : unsigned;
      recover      : unsigned;

      txBuffer     : Tcp_Tx_Buffer;
      txBufferSize : Tx_Buffer_Size;
      rxBuffer     : Tcp_Rx_Buffer;
      rxBufferSize : Rx_Buffer_Size;

      retransmitQueue : System.Address;
      retransmitTimer : Tcp_Timer;
      retransmitCount : unsigned;

      synQueue     : Tcp_Syn_Queue_Item_Acc;-- Tcp_Syn_Queue_Item_Acc;
      synQueueSize : Syn_Queue_Size;

      wndProbeCount    : unsigned;
      wndProbeInterval : Systime;

      persistTimer  : Tcp_Timer;
      overrideTimer : Tcp_Timer;
      finWait2Timer : Tcp_Timer;
      timeWaitTimer : Tcp_Timer;

      sackPermitted  : Bool;
      sackBlock      : SackBlockArray;
      sackBlockCount : unsigned;

      -- UDP specific variables
      receiveQueue : Socket_Queue_Item_Acc;
   end record
     with 
      Convention => C,
      Predicate =>
         Socket_Struct.S_Event_Mask = SOCKET_EVENT_TIMEOUT or else
         Socket_Struct.S_Event_Mask = SOCKET_EVENT_CONNECTED or else
         Socket_Struct.S_Event_Mask = SOCKET_EVENT_CLOSED or else
         Socket_Struct.S_Event_Mask = SOCKET_EVENT_TX_READY or else
         Socket_Struct.S_Event_Mask = SOCKET_EVENT_TX_DONE or else
         Socket_Struct.S_Event_Mask = SOCKET_EVENT_TX_ACKED or else
         Socket_Struct.S_Event_Mask = SOCKET_EVENT_TX_SHUTDOWN or else
         Socket_Struct.S_Event_Mask = SOCKET_EVENT_RX_READY or else
         Socket_Struct.S_Event_Mask = SOCKET_EVENT_RX_SHUTDOWN or else
         Socket_Struct.S_Event_Mask = (SOCKET_EVENT_CONNECTED or SOCKET_EVENT_CLOSED);

   -- @brief Flags used by I/O functions

   subtype Socket_Flags is unsigned;

   SOCKET_FLAG_PEEK       : constant Socket_Flags := 16#0200#;
   SOCKET_FLAG_DONT_ROUTE : constant Socket_Flags := 16#0400#;
   SOCKET_FLAG_WAIT_ALL   : constant Socket_Flags := 16#0800#;
   SOCKET_FLAG_DONT_WAIT  : constant Socket_Flags := 16#0100#;
   SOCKET_FLAG_BREAK_CHAR : constant Socket_Flags := 16#1000#;
   SOCKET_FLAG_BREAK_CRLF : constant Socket_Flags := 16#100A#;
   SOCKET_FLAG_WAIT_ACK   : constant Socket_Flags := 16#2000#;
   SOCKET_FLAG_NO_DELAY   : constant Socket_Flags := 16#4000#;
   SOCKET_FLAG_DELAY      : constant Socket_Flags := 16#8000#;

   -- Number of sockets that can be opened simultaneously
   
#if SOCKET_MAX_COUNT'Defined then
   SOCKET_MAX_COUNT : constant Positive := $SOCKET_MAX_COUNT;
#else
   SOCKET_MAX_COUNT : constant Positive := 16;
#end if;

   type Socket_Type_Index is range 0 .. (SOCKET_MAX_COUNT - 1);
   type Socket_Table_T is array (Socket_Type_Index) of aliased Socket_Struct;

   Socket_Table : aliased Socket_Table_T
     with
      Import        => True,
      Convention    => C,
      External_Name => "socketTable";

   type Socket is access Socket_Struct;
   subtype Not_Null_Socket is not null Socket;

   SOCKET_EPHEMERAL_PORT_MIN : constant Port := 49_152;
   SOCKET_EPHEMERAL_PORT_MAX : constant Port := 65_535;

   ------------------------------
   -- Ghost Sockets for Proofs --
   ------------------------------

   type Socket_Model is record
      -- S_Descriptor    : Sock_Descriptor;
      S_Type          : Socket_Type;
      S_Protocol      : Socket_Protocol;
      S_localIpAddr   : IpAddr;
      S_Local_Port    : Port;
      S_Remote_Ip_Addr  : IpAddr;
      S_Remote_Port   : Port;
      -- S_Timeout       : Systime;
      -- S_TTL           : unsigned_char;
      -- S_Multicast_TTL : unsigned_char;
      S_State         : Tcp_State;
      -- S_Tx_Buffer_Size: Tx_Buffer_Size;
      -- S_Rx_Buffer_Size: Rx_Buffer_Size;
      S_Reset_Flag    : Bool;
      S_Owned_Flag    : Bool;
   end record
     with Ghost;

   function Model (Sock : not null access constant Socket_Struct) return Socket_Model is
     (Socket_Model'(
         -- S_Descriptor     => Sock.S_Descriptor,
         S_Type           => Sock.S_Type,
         S_Protocol       => Sock.S_Protocol,
         S_localIpAddr    => Sock.S_localIpAddr,
         S_Local_Port     => Sock.S_Local_Port,
         S_Remote_Ip_Addr => Sock.S_Remote_Ip_Addr,
         S_Remote_Port    => Sock.S_Remote_Port,
         -- S_Timeout        => Sock.S_Timeout,
         -- S_TTL            => Sock.S_TTL,
         -- S_Multicast_TTL  => Sock.S_Multicast_TTL,
         S_State          => Sock.State,
         -- S_Rx_Buffer_Size => Sock.rxBufferSize,
         -- S_Tx_Buffer_Size => Sock.txBufferSize
         S_Reset_Flag     => Sock.reset_Flag,
         S_Owned_Flag     => Sock.owned_Flag
     ))
     with Ghost;

   -- Basic Socket Model is here to model a socket after a procedure
   -- call that fail et return an error.
   -- It allows to model that we don't know everything about the TCP
   -- state, but we still know what kind of protocol the socket is using

   type Basic_Socket_Model is record
      S_Type           : Socket_Type;
      S_Protocol       : Socket_Protocol;
      S_localIpAddr    : IpAddr;
      S_Local_Port     : Port;
      S_Remote_Ip_Addr : IpAddr;
      S_Remote_Port    : Port;
   end record with Ghost;

   function Basic_Model(Sock : not null access constant Socket_Struct) return Basic_Socket_Model is
      (Basic_Socket_Model'(
         S_Type           => Sock.S_Type,
         S_Protocol       => Sock.S_Protocol,
         S_localIpAddr    => Sock.S_localIpAddr,
         S_Local_Port     => Sock.S_Local_Port,
         S_Remote_Ip_Addr => Sock.S_Remote_Ip_Addr,
         S_Remote_Port    => Sock.S_Remote_Port
      ))
      with Ghost;
   

   -- The transition relation function is used to compute all the transitions
   -- that can happen when a message is received.
   -- This function can be used (for example) in loop invariant to compute
   -- all the transition that can happen while receiving data
   -- or in a loop that sends data.

   -- This function represents only the direct transitions and the
   -- transition to closed when a RST segment is received isn't
   -- considered because this case must always be filtered by checking the returned
   -- code of the function, and thus, may not appear in a loop invariant
   function TCP_Rel
      (Model_Before : Socket_Model;
       Model_After  : Socket_Model)
   return Boolean is
      (-- Basic attributes of the socket are kept
      Model_Before.S_Type = Model_After.S_Type and then
      Model_Before.S_Protocol = Model_After.S_Protocol and then
      Model_Before.S_localIpAddr = Model_After.S_localIpAddr and then
      Model_Before.S_Local_Port = Model_After.S_Local_Port and then
      Model_Before.S_Remote_Ip_Addr = Model_After.S_Remote_Ip_Addr and then
      Model_Before.S_Remote_Port = Model_After.S_Remote_Port and then
      -- Only the TCP State is changed
      (Model_Before.S_State = Model_After.S_State or else
      (if Model_Before.S_State = TCP_STATE_SYN_SENT then
         Model_After.S_State = TCP_STATE_SYN_RECEIVED or else
         Model_After.S_State = TCP_STATE_ESTABLISHED
      elsif Model_Before.S_State = TCP_STATE_SYN_RECEIVED then
         Model_After.S_State = TCP_STATE_ESTABLISHED
      elsif Model_Before.S_State = TCP_STATE_ESTABLISHED then
         Model_After.S_State = TCP_STATE_CLOSE_WAIT
      elsif Model_Before.S_State = TCP_STATE_LAST_ACK then
         Model_After.S_State = TCP_STATE_CLOSED
      elsif Model_Before.S_State = TCP_STATE_FIN_WAIT_1 then
         Model_After.S_State = TCP_STATE_FIN_WAIT_2 or else
         Model_After.S_State = TCP_STATE_TIME_WAIT or else
         Model_After.S_State = TCP_STATE_CLOSING
      elsif Model_Before.S_State = TCP_STATE_FIN_WAIT_2 then
         Model_After.S_State = TCP_STATE_TIME_WAIT
      elsif Model_Before.S_State = TCP_STATE_CLOSING then
         Model_After.S_State = TCP_STATE_TIME_WAIT
      elsif Model_Before.S_State = TCP_STATE_TIME_WAIT then
         Model_After.S_State = TCP_STATE_CLOSED)
      ))
   with Ghost;

   -- Transitive closure of the function TCP_Rel
   function TCP_Rel_Iter
      (Model_Before : Socket_Model;
       Model_After  : Socket_Model)
   return Boolean is
      (-- Basic attributes of the socket are kept
      Model_After.S_Type = Model_Before.S_Type and then
      Model_After.S_Protocol = Model_Before.S_Protocol and then
      Model_After.S_localIpAddr = Model_Before.S_localIpAddr and then
      Model_After.S_Local_Port = Model_Before.S_Local_Port and then
      Model_After.S_Remote_Ip_Addr = Model_Before.S_Remote_Ip_Addr and then
      Model_After.S_Remote_Port = Model_Before.S_Remote_Port and then
      -- Only the TCP State is changed
      (
         Model_After.S_State = Model_Before.S_State or else
         (if Model_Before.S_State = TCP_STATE_SYN_SENT then
            Model_After.S_State = TCP_STATE_SYN_RECEIVED or else
            Model_After.S_State = TCP_STATE_ESTABLISHED or else
            Model_After.S_State = TCP_STATE_CLOSE_WAIT
         elsif Model_Before.S_State = TCP_STATE_SYN_RECEIVED then
            Model_After.S_State = TCP_STATE_ESTABLISHED or else
            Model_After.S_State = TCP_STATE_CLOSE_WAIT
         elsif Model_Before.S_State = TCP_STATE_ESTABLISHED then
            Model_After.S_State = TCP_STATE_CLOSE_WAIT
         elsif Model_Before.S_State = TCP_STATE_LAST_ACK then
            Model_After.S_State = TCP_STATE_CLOSED
         elsif Model_Before.S_State = TCP_STATE_FIN_WAIT_1 then
            Model_After.S_State = TCP_STATE_FIN_WAIT_2 or else
            Model_After.S_State = TCP_STATE_TIME_WAIT or else
            Model_After.S_State = TCP_STATE_CLOSING or else
            Model_After.S_State = TCP_STATE_CLOSED
         elsif Model_Before.S_State = TCP_STATE_FIN_WAIT_2 then
            Model_After.S_State = TCP_STATE_TIME_WAIT or else
            Model_After.S_State = TCP_STATE_CLOSED
         elsif Model_Before.S_State = TCP_STATE_CLOSING then
            Model_After.S_State = TCP_STATE_TIME_WAIT or else
            Model_After.S_State = TCP_STATE_CLOSED
         elsif Model_Before.S_State = TCP_STATE_TIME_WAIT then
            Model_After.S_State = TCP_STATE_CLOSED
         else
            Model_After.S_State = Model_Before.S_State
         )))
   with Ghost;

end Socket_Types;
