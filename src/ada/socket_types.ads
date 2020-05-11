with Common_Type;  use Common_Type;
with Interfaces.C; use Interfaces.C;
with Ip;           use Ip;
with OS;           use Os;
with System;
with Tcp_Type;     use Tcp_Type;

package Socket_Types
   with SPARK_Mode
is

   type SackBlockArray is array (0 .. 3) of Tcp_Sack_Block;


   ------------------
   -- Socket_Event --
   ------------------

   type Socket_Event is mod 2 ** 10;

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

   -----------------------
   -- Socket Definition --
   -----------------------

   type Socket_Struct is record
      S_Descriptor    : Sock_Descriptor;
      S_Type          : Sock_Type;
      S_Protocol      : Sock_Protocol;
      S_Net_Interface : System.Address;
      S_localIpAddr   : IpAddr;
      S_Local_Port    : Port;
      S_remoteIpAddr  : IpAddr;
      S_Remote_Port   : Port;
      S_Timeout       : Systime;
      S_TTL           : unsigned_char;
      S_Multicast_TTL : unsigned_char;
      S_Errno_Code    : int;
      S_Event         : Os_Event;
      S_Event_Mask    : Socket_Event;
      S_Event_Flags   : Socket_Event;
      userEvent       : System.Address;

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
      synQueueSize : unsigned;

      wndProbeCount    : unsigned;
      wndProbeInterval : Systime;

      persistTimer  : Tcp_Timer;
      overrideTimer : Tcp_Timer;
      finWait2Timer : Tcp_Timer;
      timeWaitTimer : Tcp_Timer;

      sackPermitted  : Bool;
      sackBlock      : SackBlockArray;
      sackBlockCount : unsigned;

      receiveQueue : System.Address;
   end record
     with Convention => C;

   type Socket_Type is
     (SOCKET_TYPE_UNUSED,
      SOCKET_TYPE_STREAM,
      SOCKET_TYPE_DGRAM,
      SOCKET_TYPE_RAW_IP,
      SOCKET_TYPE_RAW_ETH);

   for Socket_Type use
     (SOCKET_TYPE_UNUSED  => 0,
      SOCKET_TYPE_STREAM  => 1,
      SOCKET_TYPE_DGRAM   => 2,
      SOCKET_TYPE_RAW_IP  => 3,
      SOCKET_TYPE_RAW_ETH => 4);


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

   SOCKET_MAX_COUNT : constant Positive := 10;
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
      S_Descriptor    : Sock_Descriptor;
      S_Type          : Sock_Type;
      S_Protocol      : Sock_Protocol;
      S_localIpAddr   : IpAddr;
      S_Local_Port    : Port;
      S_remoteIpAddr  : IpAddr;
      S_Remote_Port   : Port;
      S_Timeout       : Systime;
      S_TTL           : unsigned_char;
      S_Multicast_TTL : unsigned_char;
      S_State         : Tcp_State;
      S_Tx_Buffer_Size: Tx_Buffer_Size;
      S_Rx_Buffer_Size: Rx_Buffer_Size;
   end record
     with Ghost;


   function Model (Sock : Not_Null_Socket) return Socket_Model is
     (Socket_Model'(
         S_Descriptor     => Sock.S_Descriptor,
         S_Type           => Sock.S_Type,
         S_Protocol       => Sock.S_Protocol,
         S_localIpAddr    => Sock.S_localIpAddr,
         S_Local_Port     => Sock.S_Local_Port,
         S_remoteIpAddr   => Sock.S_remoteIpAddr,
         S_Remote_Port    => Sock.S_Remote_Port,
         S_Timeout        => Sock.S_Timeout,
         S_TTL            => Sock.S_TTL,
         S_Multicast_TTL  => Sock.S_Multicast_TTL,
         S_State          => Sock.State,
         S_Rx_Buffer_Size => Sock.rxBufferSize,
         S_Tx_Buffer_Size => Sock.txBufferSize
     ))
     with Ghost;

end Socket_Types;
