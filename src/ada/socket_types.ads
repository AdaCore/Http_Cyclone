with Interfaces.C; use Interfaces.C;
with Tcp_Type;     use Tcp_Type;
with Common_Type;  use Common_Type;
with System;
with Ip;           use Ip;

package Socket_Types is

   type SackBlockArray is array (0 .. 3) of Tcp_Sack_Block;

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
      S_errnoCode     : int;
      S_event         : OsEvent;
      S_Event_Mask    : unsigned;
      S_Event_Flags   : unsigned;
      userEvent       : System.Address;

      -- TCP specific variables
      State       : Tcp_State;
      owned_Flag  : Bool;
      closed_Flag : Bool;
      reset_Flag  : Bool;

      smss : unsigned_short;
      rmss : unsigned_short;
      iss  : unsigned_long;
      irs  : unsigned_long;

      sndUna    : unsigned_long;
      sndNxt    : unsigned_long;
      sndUser   : unsigned_short;
      sndWnd    : unsigned_short;
      maxSndWnd : unsigned_short;
      sndWl1    : unsigned_long;
      sndWl2    : unsigned_long;

      rcvNxt  : unsigned_long;
      rcvUser : unsigned_short;
      rcvWnd  : unsigned_short;

      rttBusy       : Bool;
      rttSeqNum     : unsigned_long;
      rettStartTime : Systime;
      srtt          : Systime;
      rttvar        : Systime;
      rto           : Systime;

      congestState : TCP_Congest_State;
      cwnd         : unsigned_short;
      ssthresh     : unsigned_short;
      dupAckCount  : unsigned;
      n            : unsigned;
      recover      : unsigned_long;

      txBuffer     : Tcp_Tx_Buffer;
      txBufferSize : unsigned_long;
      rxBuffer     : Tcp_Rx_Buffer;
      rxBufferSize : unsigned_long;

      retransmitQueue : System.Address;
      retransmitTimer : Tcp_Timer;
      retransmitCount : unsigned;

      synQueue     : System.Address;
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

   type Socket_Event is
     (SOCKET_EVENT_TIMEOUT,
      SOCKET_EVENT_CONNECTED,
      SOCKET_EVENT_CLOSED,
      SOCKET_EVENT_TX_READY,
      SOCKET_EVENT_TX_DONE,
      SOCKET_EVENT_TX_ACKED,
      SOCKET_EVENT_TX_SHUTDOWN,
      SOCKET_EVENT_RX_READY,
      SOCKET_EVENT_RX_SHUTDOWN,
      SOCKET_EVENT_LINK_UP,
      SOCKET_EVENT_LINK_DOWN);

   for Socket_Event use
     (SOCKET_EVENT_TIMEOUT     => 000,
      SOCKET_EVENT_CONNECTED   => 001,
      SOCKET_EVENT_CLOSED      => 002,
      SOCKET_EVENT_TX_READY    => 004,
      SOCKET_EVENT_TX_DONE     => 008,
      SOCKET_EVENT_TX_ACKED    => 016,
      SOCKET_EVENT_TX_SHUTDOWN => 032,
      SOCKET_EVENT_RX_READY    => 064,
      SOCKET_EVENT_RX_SHUTDOWN => 128,
      SOCKET_EVENT_LINK_UP     => 256,
      SOCKET_EVENT_LINK_DOWN   => 512);

   SOCKET_MAX_COUNT : constant Positive := 10;
   type Socket_Type_Index is range 0 .. (SOCKET_MAX_COUNT - 1);
   type Socket_Table_T is array (Socket_Type_Index) of aliased Socket_Struct;

   Socket_Table : aliased Socket_Table_T
     with
      Import        => True,
      Convention    => C,
      External_Name => "socketTable";

   type Socket is access Socket_Struct;

   SOCKET_EPHEMERAL_PORT_MIN : constant Port := 49_152;
   SOCKET_EPHEMERAL_PORT_MAX : constant Port := 65_535;

end Socket_Types;
