with Os;            use Os;
with Socket_Helper; use Socket_Helper;
with System;
with Tcp_Type;      use Tcp_Type;

package body Socket_interface
   with SPARK_Mode
is

   procedure Get_Host_By_Name
     (Server_Name    :     char_array;
      Server_Ip_Addr : out IpAddr;
      Flags          :     Host_Resolver_Flags;
      Error          : out Error_T)
   is
      F : Natural := 0;
   begin
      for I in Flags'Range loop
         pragma Loop_Invariant (F <= I * 32);
         F := F + Host_Resolver'Enum_Rep (Flags (I));  -- ??? can you get a bound on the size of Flags?
      end loop;
      Get_Host_By_Name_H (Server_Name, Server_Ip_Addr, unsigned (F), Error);
   end Get_Host_By_Name;

   procedure Socket_Open
     (Sock       : out Socket;
      S_Type     :     Socket_Type;
      S_Protocol :     Socket_Protocol)
   is
      Error    : Error_T;
      P        : Port;
      Protocol : Socket_Protocol := S_Protocol;
   begin
      -- Initialize socket handle
      Sock := null;
      Os_Acquire_Mutex (Net_Mutex);

      case S_Type is
         when SOCKET_TYPE_STREAM =>
            -- Always use TCP as underlying transport protocol
            Protocol := SOCKET_IP_PROTO_TCP;
            -- Get an ephemeral port number
            Tcp_Get_Dynamic_Port (P);
            Error := NO_ERROR;
         when SOCKET_TYPE_DGRAM =>
            --Always use UDP as underlying transport protocol
            Protocol := SOCKET_IP_PROTO_UDP;
            -- Get an ephemeral port number
            P     := Udp_Get_Dynamic_Port;
            Error := NO_ERROR;
         when SOCKET_TYPE_RAW_IP | SOCKET_TYPE_RAW_ETH =>
            P     := 0;
            Error := NO_ERROR;
         when others =>
            P     := 0;
            Error := ERROR_INVALID_PARAMETER;
      end case;

      if Error = NO_ERROR then
         for I in Socket_Table'Range loop
            if Socket_Table (I).S_Type =
              Socket_Type'Enum_Rep (SOCKET_TYPE_UNUSED)
            then
               -- Save socket handle
               Get_Socket_From_Table (I, Sock);
               -- We are done
               exit;
            end if;
         end loop;

         if Sock = null then
            -- Kill the oldest connection in the TIME-WAIT state whenever the
            -- socket table runs out of space
            Tcp_Kill_Oldest_Connection (Sock);
         end if;

         -- Check whether the current entry is free
         if Sock /= null then
            -- Reset Socket
            -- Maybe there is a simplest way to perform that in Ada
            Sock.S_Type                := Socket_Type'Enum_Rep (S_Type);
            Sock.S_Protocol            := Socket_Protocol'Enum_Rep (Protocol);
            Sock.S_Local_Port          := P;
            Sock.S_Timeout             := Systime'Last;
            Sock.S_remoteIpAddr.length := 0;
            Sock.S_localIpAddr.length  := 0;
            Sock.S_Remote_Port         := 0;
            Sock.S_Net_Interface       := System.Null_Address;
            Sock.S_TTL                 := 0;
            Sock.S_Multicast_TTL       := 0;
            Sock.S_errnoCode           := 0;
            Sock.S_Event_Mask          := 0;
            Sock.S_Event_Flags         := 0;
            Sock.userEvent             := System.Null_Address;
            Sock.State                 := TCP_STATE_CLOSED;
            Sock.owned_Flag            := 0;
            Sock.closed_Flag           := 0;
            Sock.reset_Flag            := 0;
            Sock.smss                  := 0;
            Sock.rmss                  := 0;
            Sock.iss                   := 0;
            Sock.irs                   := 0;
            Sock.sndUna                := 0;
            Sock.sndNxt                := 0;
            Sock.sndUser               := 0;
            Sock.sndWnd                := 0;
            Sock.maxSndWnd             := 0;
            Sock.sndWl1                := 0;
            Sock.sndWl2                := 0;
            Sock.rcvNxt                := 0;
            Sock.rcvUser               := 0;
            Sock.rcvWnd                := 0;
            Sock.rttBusy               := 0;
            Sock.rttSeqNum             := 0;
            Sock.rettStartTime         := 0;
            Sock.srtt                  := 0;
            Sock.rttvar                := 0;
            Sock.rto                   := 0;
            Sock.congestState          := TCP_CONGEST_STATE_IDLE;
            Sock.cwnd                  := 0;
            Sock.ssthresh              := 0;
            Sock.dupAckCount           := 0;
            Sock.n                     := 0;
            Sock.recover               := 0;
            Sock.txBuffer.chunkCount   := 0;
            Sock.txBufferSize          := 2_860;
            Sock.rxBuffer.chunkCount   := 0;
            Sock.rxBufferSize          := 2_860;
            Sock.retransmitQueue       := System.Null_Address;
            Sock.retransmitCount       := 0;
            Sock.synQueue              := System.Null_Address;
            Sock.synQueueSize          := 0;
            Sock.wndProbeCount         := 0;
            Sock.wndProbeInterval      := 0;
            Sock.sackPermitted         := 0;
            Sock.sackBlockCount        := 0;
            Sock.receiveQueue          := System.Null_Address;
         end if;
      end if;

      Os_Release_Mutex (Net_Mutex);
   end Socket_Open;

   procedure Socket_Set_Timeout
     (Sock    : in out Socket;
      Timeout :        Systime)
   is
   begin
      Os_Acquire_Mutex (Net_Mutex);
      Sock.S_Timeout := Timeout;
      Os_Release_Mutex (Net_Mutex);
   end Socket_Set_Timeout;

   procedure Socket_Set_Ttl
     (Sock : in out Socket;
      Ttl  :        Ttl_Type)
   is
   begin
      Os_Acquire_Mutex (Net_Mutex);
      Sock.S_TTL := unsigned_char (Ttl);
      Os_Release_Mutex (Net_Mutex);
   end Socket_Set_Ttl;

   procedure Socket_Set_Multicast_Ttl
     (Sock : in out Socket;
      Ttl  :        Ttl_Type)
   is
   begin
      Os_Acquire_Mutex (Net_Mutex);
      Sock.S_Multicast_TTL := unsigned_char (Ttl);
      Os_Release_Mutex (Net_Mutex);
   end Socket_Set_Multicast_Ttl;

   procedure Socket_Connect
     (Sock           : in out Socket;
      Remote_Ip_Addr : in     IpAddr;
      Remote_Port    : in     Port;
      Error          :    out Error_T)
   is
   begin
      -- Connection oriented socket?
      if Sock.S_Type = Socket_Type'Enum_Rep (SOCKET_TYPE_STREAM) then
         Os_Acquire_Mutex (Net_Mutex);
         -- Establish TCP connection
         Tcp_Connect (Sock, Remote_Ip_Addr, Remote_Port, Error);
         Os_Release_Mutex (Net_Mutex);

         -- Connectionless socket?
      elsif Sock.S_Type = Socket_Type'Enum_Rep (SOCKET_TYPE_DGRAM) then
         Sock.S_remoteIpAddr := Remote_Ip_Addr;
         Sock.S_Remote_Port  := Remote_Port;
         Error               := NO_ERROR;

         -- Raw Socket?
      elsif Sock.S_Type = Socket_Type'Enum_Rep (SOCKET_TYPE_RAW_IP) then
         Sock.S_remoteIpAddr := Remote_Ip_Addr;
         Error               := NO_ERROR;
      else
         Error := ERROR_INVALID_SOCKET;
      end if;
   end Socket_Connect;

   procedure Socket_Send_To
     (Sock         : in out Socket;
      Dest_Ip_Addr :        IpAddr;
      Dest_Port    :        Port;
      Data         : in     char_array;
      Written      :    out Integer;
      Flags        :        unsigned;
      Error        :    out Error_T)
   is
   begin
      Written := 0;
      Os_Acquire_Mutex (Net_Mutex);
        --@TODO : finish
      if Sock.S_Type = Socket_Type'Enum_Rep (SOCKET_TYPE_STREAM) then
         Tcp_Send (Sock, Data, Written, Flags, Error);
      else
         Error := ERROR_INVALID_SOCKET;
      end if;
      Os_Release_Mutex (Net_Mutex);
   end Socket_Send_To;

   procedure Socket_Send
     (Sock    : in out Socket;
      Data    : in     char_array;
      Written :    out Integer;
      Error   :    out Error_T)
   is
   begin
      Written := 0;
      Os_Acquire_Mutex (Net_Mutex);
      if Sock.S_Type = Socket_Type'Enum_Rep (SOCKET_TYPE_STREAM) then
         Tcp_Send (Sock, Data, Written, 0, Error);
      else
         Error := ERROR_INVALID_SOCKET;
      end if;
      Os_Release_Mutex (Net_Mutex);
   end Socket_Send;

   procedure Socket_Receive_Ex
     (Sock         : in out Socket;
      Src_Ip_Addr  :    out IpAddr;
      Src_Port     :    out Port;
      Dest_Ip_Addr :    out IpAddr;
      Data         :    out char_array;
      Received     :    out unsigned;
      Flags        :        unsigned;
      Error        :    out Error_T)
   is
   begin

      Os_Acquire_Mutex (Net_Mutex);
      if Sock.S_Type = SOCKET_TYPE_STREAM'Enum_Rep then
         Tcp_Receive (Sock, Data, Received, Flags, Error);
         Src_Ip_Addr  := Sock.S_remoteIpAddr;
         Src_Port     := Sock.S_Remote_Port;
         Dest_Ip_Addr := Sock.S_localIpAddr;
         -- elsif Sock.S_Type = Socket_Type'Enum_Rep(SOCKET_TYPE_DGRAM) then
         --     Error := udp_Receive_Datagram(Sock, Src_Ip_Addr, Src_Port, Dest_Ip_Addr, Data, Data'Length, Size, Received, Flags);
      else
         Src_Ip_Addr  := Sock.S_remoteIpAddr;
         Src_Port     := Sock.S_Remote_Port;
         Dest_Ip_Addr := Sock.S_localIpAddr;
         Error        := ERROR_INVALID_SOCKET;
         Received     := 0;
         Data         := (others => nul);
      end if;
      Os_Release_Mutex (Net_Mutex);
   end Socket_Receive_Ex;

   procedure Socket_Receive
     (Sock     : in out Socket;
      Data     :    out char_array;
      Received :    out unsigned;
      Error    :    out Error_T)
   is
      Ignore_Src_Ip, Ignore_Dest_Ip : IpAddr;
      Ignore_Src_Port               : Port;
   begin
      Socket_Receive_Ex
        (Sock, Ignore_Src_Ip, Ignore_Src_Port, Ignore_Dest_Ip, Data, Received,
         0, Error);
   end Socket_Receive;

   procedure Socket_Shutdown
     (Sock  : in out Socket;
      How   :        Socket_Shutdown_Flags;
      Error :    out Error_T)
   is
   begin
      if Sock = null then
         Error := ERROR_INVALID_PARAMETER;
         return;
      end if;

      Os_Acquire_Mutex (Net_Mutex);
      Tcp_Shutdown (Sock, Socket_Shutdown_Flags'Enum_Rep (How), Error);
      Os_Release_Mutex (Net_Mutex);
   end Socket_Shutdown;

   procedure Socket_Close (Sock : in out Socket) is
      Ignore_Error : Error_T;
   begin
      -- Get exclusive access
      Os_Acquire_Mutex (Net_Mutex);

      if Sock = null then
         return;
      end if;

      if (Sock.S_Type = SOCKET_TYPE_STREAM'Enum_Rep) then
         Tcp_Abort (Sock, Ignore_Error);
      elsif Sock.S_Type = SOCKET_TYPE_DGRAM'Enum_Rep
        or else Sock.S_Type = SOCKET_TYPE_RAW_IP'Enum_Rep
        or else Sock.S_Type = SOCKET_TYPE_RAW_ETH'Enum_Rep
      then

         -- @TODO : Purge the receive queue

         -- Mark the socket as closed
         Sock.S_Type := SOCKET_TYPE_UNUSED'Enum_Rep;
      else
         -- All others cases that need to be considered to be coherent with the
         -- C code but that won't never appear.
         Sock.S_Type := SOCKET_TYPE_UNUSED'Enum_Rep;
      end if;

      -- Release exclusive access
      Os_Release_Mutex (Net_Mutex);
   end Socket_Close;

   procedure Socket_Set_Tx_Buffer_Size
     (Sock : in out Socket;
      Size :        Buffer_Size)
   is
   begin
        --@TODO check
      Sock.txBufferSize := unsigned_long (Size);
   end Socket_Set_Tx_Buffer_Size;

   procedure Socket_Set_Rx_Buffer_Size
     (Sock : in out Socket;
      Size :        Buffer_Size)
   is
   begin
        --@TODO check
      Sock.rxBufferSize := unsigned_long (Size);
   end Socket_Set_Rx_Buffer_Size;

   procedure Socket_Bind
     (Sock          : in out Socket;
      Local_Ip_Addr :        IpAddr;
      Local_Port    :        Port)
   is
   begin
      Sock.S_localIpAddr := Local_Ip_Addr;
      Sock.S_Local_Port  := Local_Port;
   end Socket_Bind;

   procedure Socket_Listen
     (Sock    : in out Socket;
      Backlog :        Natural;
      Error   :    out Error_T)
   is
   begin
      Os_Acquire_Mutex (Net_Mutex);
      Tcp_Listen (Sock, unsigned (Backlog), Error);
      Os_Release_Mutex (Net_Mutex);
   end Socket_Listen;

   procedure Socket_Accept
     (Sock           : in out Socket;
      Client_Ip_Addr :    out IpAddr;
      Client_Port    :    out Port;
      Client_Socket  :    out Socket)
   is
   begin
      Tcp_Accept (Sock, Client_Ip_Addr, Client_Port, Client_Socket);
   end Socket_Accept;

end Socket_interface;
