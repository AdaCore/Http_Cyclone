with Interfaces.C; use Interfaces.C;
with Net; use Net;
with Compiler_Port; use Compiler_Port;
with Tcp; use Tcp;
with Error_H; use Error_H;
with Systeme;

package Socket_Binding is

   MAX_BYTES : constant := 128

   type Sock_Descriptor is new unsigned;
   type Sock_Type is new unsigned;
   type Sock_Protocol is new unsigned;
   type Sock_Port is new unsigned_short;
   type SackBlockArray is array (0 .. 3) of Tcp_Sack_Block;
   type uint8 is mod 2 ** 8;
   subtype Index is unsigned range 0 .. MAX_BYTES;
   type Block8 is array (Index range <>) of uint8;

   type OsEvent is
      record
         handle: access TcpQueueItem;
      end record
     with Convention => C;
   
   -- type Socket is 
   --    record
   --       S_Descriptor: Sock_Descriptor;
   --       S_Type: Sock_Type;
   --       S_Protocol: Sock_Protocol;
   --       S_NetInterface: access Net_Interface;
   --       S_localIpAddr: IpAddr;
   --       S_Local_Port: Sock_Port;
   --       S_remoteIpAddr: IpAddr;
   --       S_Remote_Port: Sock_Port;
   --       S_Timeout: Compiler_Port.Systime;
   --       S_TTL: unsigned_char;
   --       S_Multicast_TTL: unsigned_char;
   --       S_errnoCode: int;
   --       S_event: OsEvent;
   --       S_Event_Mask: unsigned;
   --       S_Event_Flags: unsigned;
   --       userEvent: access OsEvent;
         
   --       -- TCP specific variables
   --       State: Tcp_State;
   --       owned_Flag: Bool;
   --       closed_Flag: Bool;
   --       reset_Flag: Bool;
         
   --       smss: unsigned_short;
   --       rmss: unsigned_short;
   --       iss: unsigned_long;
   --       irs: unsigned_long;
         
   --       sndUna: unsigned_long;
   --       sndNxt: unsigned_long;
   --       sndUser: unsigned_short;
   --       sndWnd: unsigned_short;
   --       maxSndWnd: unsigned_short;
   --       sndWl1: unsigned_long;
   --       sndWl2: unsigned_long;
         
   --       rcvNxt: unsigned_long;
   --       rcvUser: unsigned_short;
   --       rcvWnd: unsigned_short;
         
   --       rttBusy: Bool;
   --       rttSeqNum: unsigned_long;
   --       rettStartTime: Systime;
   --       srtt: Systime;
   --       rttvar: Systime;
   --       rto: Systime;
         
   --       congestState: TCP_Congest_State;
   --       cwnd: unsigned_short;
   --       ssthresh: unsigned_short;
   --       dupAckCount: unsigned;
   --       n: unsigned;
   --       recover: unsigned_long;
         
   --       txBuffer: Tcp_Tx_Buffer;
   --       txBufferSize: unsigned_long;
   --       rxBuffer: Tcp_Rx_Buffer;
   --       rxBufferSize: unsigned_long;
         
   --       retransmitQueue: access TcpQueueItem;
   --       retransmitTimer: Tcp_Timer;
   --       retransmitCount: unsigned;
         
   --       -- TODO: Not good type. Just used to denote a pointer
   --       synQueue: access TcpQueueItem;
   --       synQueueSize: unsigned;
         
   --       wndProbeCount: unsigned;
   --       wndProbeInterval: Systime;
         
   --       persistTimer: Tcp_Timer;
   --       overrideTimer: Tcp_Timer;
   --       finWait2Timer: Tcp_Timer;
   --       timeWaitTimer: Tcp_Timer;
         
   --       sackPermitted: Bool;
   --       sackBlock: SackBlockArray;
   --       sackBlockCount: unsigned;
         
   --       -- TODO: should be socketQueueItem here
   --       receiveQueue: access TcpQueueItem;
         
   --    end record
   --   with Convention => C;

   type Socket is new Systeme.Address;
   type IpAddr is new Systeme.Address;

   function socketOpen (S_Type: Sock_Type; protocol: Sock_Protocol) return Socket
     with
       Import => True,
       Convention => C,
       External_Name => "socketOpen";

   function socketSetTimeout (sock: Socket; timeout: Systime) return Error_T
    with
      Import => True,
      Convention => C,
      External_Name => "socketSetTimeout";
   
   function socketConnect (sock: Socket; remoteIpAddr: IpAddr; remotePort: Sock_Port)
   return  Error_T
   with
      Import => True,
      Convention => C,
      External_Name => "socketConnect";

   function socketSend (sock: Socket; data: Block8; length: unsigned; written: out unsigned; flags: unsigned)
   return Error_T
   with
      Import => True,
      Convention => C,
      External_Name => "socketSend";

   function socketReceive(sock: Socket; data: out Block8; size: unsigned; received: out unsigned; flags: unsigned)
   return Error_T
   with
      Import => True,
      Convention => C,
      External_Name => "socketReceive";

   function socketShutdown (sock: Socket; how: unsigned)
   return Error_T
   with
      Import => True,
      Convention => C,
      External_Name => "socketShutdown";

   procedure socketClose (sock: Socket)
   with
      Import => True,
      Convention => C,
      External_Name => "socketClose";


   
end Socket_Binding;
