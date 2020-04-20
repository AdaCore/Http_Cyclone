with Interfaces.C; use Interfaces.C;
-- with Compiler_Port; use Compiler_Port;
with Tcp; use Tcp;
with Error_H; use Error_H;
with System;
with Ip; use Ip;

package Socket_Binding is

   MAX_BYTES : constant := 128;

   -- type IpAddr is new System.Address;

   type Bool is new int;
   type Systime is new unsigned_long;

   type Sock_Descriptor is new unsigned;
   type Sock_Type is new unsigned;
   type Sock_Protocol is new unsigned;
   type Sock_Port is new unsigned_short;
   type SackBlockArray is array (0 .. 3) of Tcp_Sack_Block;
   type uint8 is mod 2 ** 8;
   subtype Index is unsigned range 0 .. MAX_BYTES;
   type Block8 is array (Index range <>) of uint8;

   type OsEvent is record
         handle: System.Address;
      end record
     with Convention => C;
   
   type Socket is record
         S_Descriptor: Sock_Descriptor;
         S_Type: Sock_Type;
         S_Protocol: Sock_Protocol;
         S_NetInterface: System.Address;
         S_localIpAddr: IpAddr;
         S_Local_Port: Sock_Port;
         S_remoteIpAddr: IpAddr;
         S_Remote_Port: Sock_Port;
         S_Timeout: Systime;
         S_TTL: unsigned_char;
         S_Multicast_TTL: unsigned_char;
         S_errnoCode: int;
         S_event: OsEvent;
         S_Event_Mask: unsigned;
         S_Event_Flags: unsigned;
         userEvent: System.Address;
         
         -- TCP specific variables
         State: Tcp_State;
         owned_Flag: Bool;
         closed_Flag: Bool;
         reset_Flag: Bool;
         
         smss: unsigned_short;
         rmss: unsigned_short;
         iss: unsigned_long;
         irs: unsigned_long;
         
         sndUna: unsigned_long;
         sndNxt: unsigned_long;
         sndUser: unsigned_short;
         sndWnd: unsigned_short;
         maxSndWnd: unsigned_short;
         sndWl1: unsigned_long;
         sndWl2: unsigned_long;
         
         rcvNxt: unsigned_long;
         rcvUser: unsigned_short;
         rcvWnd: unsigned_short;
         
         rttBusy: Bool;
         rttSeqNum: unsigned_long;
         rettStartTime: Systime;
         srtt: Systime;
         rttvar: Systime;
         rto: Systime;
         
         congestState: TCP_Congest_State;
         cwnd: unsigned_short;
         ssthresh: unsigned_short;
         dupAckCount: unsigned;
         n: unsigned;
         recover: unsigned_long;
         
         txBuffer: Tcp_Tx_Buffer;
         txBufferSize: unsigned_long;
         rxBuffer: Tcp_Rx_Buffer;
         rxBufferSize: unsigned_long;
         
         retransmitQueue: System.Address;
         retransmitTimer: Tcp_Timer;
         retransmitCount: unsigned;
         
         synQueue: System.Address;
         synQueueSize: unsigned;
         
         wndProbeCount: unsigned;
         wndProbeInterval: Systime;
         
         persistTimer: Tcp_Timer;
         overrideTimer: Tcp_Timer;
         finWait2Timer: Tcp_Timer;
         timeWaitTimer: Tcp_Timer;
         
         sackPermitted: Bool;
         sackBlock: SackBlockArray;
         sackBlockCount: unsigned;
         
         receiveQueue: System.Address;
         
      end record
     with Convention => C;

   type Socket_Struct is access Socket;
   -- 

   function getHostByName(Net_Interface : System.Address; Server_Name : char_array; Serveur_Ip_Addr: out IpAddr; Flags : unsigned)
   return unsigned
     with
      Import => True,
      Convention => C,
      External_Name => "getHostByName";

   function socketOpen (S_Type: Sock_Type; protocol: Sock_Protocol) return Socket_Struct 
   with
       Import => True,
       Convention => C,
       External_Name => "socketOpen";

   function socketSetTimeout (sock: Socket_Struct; timeout: Systime) return unsigned
    with
      Import => True,
      Convention => C,
      External_Name => "socketSetTimeout";

   function socketSetTtl(sock: Socket_Struct; ttl: unsigned_char) return unsigned
    with
      Import => True,
      Convention => C,
      External_Name => "socketSetTtl";

   function socketSetMulticastTtl(sock: Socket_Struct; ttl: unsigned_char) return unsigned
    with
      Import => True,
      Convention => C,
      External_Name => "socketSetMulticastTtl";
   
   function socketConnect (sock: Socket_Struct; remoteIpAddr: IpAddr; remotePort: Sock_Port)
   return unsigned
   with
      Import => True,
      Convention => C,
      External_Name => "socketConnect";

   function socketSend (sock: Socket_Struct; data: char_array; length: unsigned; written: out unsigned; flags: unsigned)
   return unsigned
   with
      Import => True,
      Convention => C,
      External_Name => "socketSend";

   function socketReceive(sock: Socket_Struct; data: out char_array; size: unsigned; received: out unsigned; flags: unsigned)
   return unsigned
   with
      Import => True,
      Convention => C,
      External_Name => "socketReceive";

   function socketShutdown (sock: Socket_Struct; how: unsigned)
   return unsigned
   with
      Import => True,
      Convention => C,
      External_Name => "socketShutdown";

   procedure socketClose (sock: Socket_Struct)
   with
      Import => True,
      Convention => C,
      External_Name => "socketClose";

   function socketSetTxBufferSize (sock: Socket_Struct; size: unsigned_long)
   return unsigned
   with
      Import => True,
      Convention => C,
      External_Name => "socketSetTxBufferSize";

   function socketSetRxBufferSize (sock: Socket_Struct; size: unsigned_long)
   return unsigned
   with
      Import => True,
      Convention => C,
      External_Name => "socketSetRxBufferSize";

   function socketBind (sock: Socket_Struct; localIpAddr: System.Address; localPort: Sock_Port)
   return unsigned
   with
      Import => True,
      Convention => C,
      External_Name => "socketBind";

   function socketListen (sock: Socket_Struct; backlog: unsigned)
   return unsigned
   with
      Import => True,
      Convention => C,
      External_Name => "socketListen";

   function socketAccept (sock: Socket_Struct; clientIpAddr: out IpAddr; clientPort: out Sock_Port)
   return Socket_Struct
   with
      Import => True,
      Convention => C,
      External_Name => "socketAccept";

   
end Socket_Binding;
