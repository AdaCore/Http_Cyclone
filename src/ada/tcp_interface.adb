with Ip_Binding;        use Ip_Binding;
with Net_Mem_Interface; use Net_Mem_Interface;
with Os;                use Os;
with Socket_Helper;     use Socket_Helper;
with Socket_Interface;  use Socket_Interface;
with System;            use System;
with Tcp_Binding;
with Tcp_Misc_Binding;  use Tcp_Misc_Binding;

package body Tcp_Interface with
   SPARK_Mode => On
is

   function netGetRand return unsigned
     with
       Import        => True,
       Convention    => C,
       External_Name => "netGetRand",
       Global        => null;

   --------------------------
   -- Tcp_Get_Dynamic_Port --
   --------------------------

   procedure Tcp_Get_Dynamic_Port (P : out Port) is
   begin
      -- Retrieve current port number
      P := Tcp_Dynamic_Port;
      -- Invalid port number?
      if not (P in SOCKET_EPHEMERAL_PORT_MIN .. SOCKET_EPHEMERAL_PORT_MAX) then
         P :=
           SOCKET_EPHEMERAL_PORT_MIN +
           Port(netGetRand mod unsigned
                  (SOCKET_EPHEMERAL_PORT_MAX - SOCKET_EPHEMERAL_PORT_MIN + 1));
      end if;

      if P < SOCKET_EPHEMERAL_PORT_MAX then
         Tcp_Dynamic_Port := P + 1;
      else
         Tcp_Dynamic_Port := SOCKET_EPHEMERAL_PORT_MIN;
      end if;
   end Tcp_Get_Dynamic_Port;


   -----------------
   -- Tcp_Connect --
   -----------------

   procedure Tcp_Connect
      (Sock           : in out Not_Null_Socket;
       Remote_Ip_Addr :        IpAddr;
       Remote_Port    :        Port;
       Error          :    out Error_T)
   is
      Event : Socket_Event;
   begin

      -- Check current TCP state
      if Sock.State = TCP_STATE_CLOSED then
         -- Save port number and IP address of the remote host
         Sock.S_remoteIpAddr := Remote_Ip_Addr;
         Sock.S_Remote_Port  := Remote_Port;

         -- Select the source address and the relevant network interface
         -- to use when establishing the connection
         Ip_Select_Source_Addr (
               Net_Interface => Sock.S_Net_Interface,
               Dest_Addr     => Sock.S_remoteIpAddr,
               Src_Addr      => Sock.S_localIpAddr,
               Error         => Error);
         
         
         if Error /= NO_ERROR then
            return;
         end if;

         -- Make sure the source address is valid
         if Ip_Is_Unspecified_Addr(Sock.S_localIpAddr) then
            Error := ERROR_NOT_CONFIGURED;
            return;
         end if;

         -- The user owns the socket
         Sock.owned_Flag := True;

         -- Number of chunks that comprise the TX and the RX buffers
         Sock.txBuffer.maxChunkCound := 
               Sock.txBuffer.chunk'Size / Sock.txBuffer.chunk(0)'Size;
         Sock.rxBuffer.maxChunkCound :=
               Sock.rxBuffer.chunk'Size / Sock.rxBuffer.chunk(0)'Size;
         
         -- Allocate transmit buffer
         Net_Tx_Buffer_Set_Length (Sock.txBuffer, Sock.txBufferSize, Error);

         if Error = NO_ERROR then
            Net_Rx_Buffer_Set_Length (Sock.rxBuffer, Sock.rxBufferSize, Error);
         end if;

         if Error /= NO_ERROR then
            Tcp_Delete_Control_Block (Sock);
            return;
         end if;

         -- The SMSS is the size of the largest segment that the sender can transmit
         Sock.smss := unsigned_short'Min (TCP_DEFAULT_MSS, TCP_MAX_MSS);
         -- The RMSS is the size of the largest segment the receiver is willing to accept
         Sock.rmss := unsigned_short(unsigned_long'Min 
                                       (unsigned_long(Sock.rxBufferSize), 
                                        unsigned_long(TCP_MAX_MSS)));

         -- An initial send sequence number is selected
         Sock.iss := netGetRand;

         -- Initialize TCP control block
         -- @TODO : Il y aura forcément des overflows ici.
         -- Voir avec Clément.
         Sock.sndUna := Sock.iss;
         Sock.sndNxt := Sock.iss + 1;
         Sock.rcvUser := 0;
         Sock.rcvWnd := unsigned_short(Sock.rxBufferSize);

         -- Default retransmission timeout
         Sock.rto := TCP_INITIAL_RTO;
         
         -- Default congestion state
         Sock.congestState := TCP_CONGEST_STATE_IDLE;
         
         -- @TODO voir pour l'overflow
         -- Initial congestion window
         Sock.cwnd := unsigned_short(
                        unsigned_long'Min(unsigned_long(TCP_INITIAL_WINDOW) * unsigned_long(Sock.smss),
                                          unsigned_long(Sock.txBufferSize)));
         -- Slow start threshold should be set arbitrarily high
         Sock.ssthresh := unsigned_short'Last;
         -- Recover is set to the initial send sequence number
         Sock.recover := Sock.iss;

         -- Send a SYN segment
         Tcp_Send_Segment (Sock, TCP_FLAG_SYN, Sock.iss, 0, 0, True, Error);

         -- Failed to send TCP segment?
         if Error /= NO_ERROR then
            return;
         end if;

         -- Switch to the SYN-SENT state
         Tcp_Change_State (Sock, TCP_STATE_SYN_SENT);
      end if;

      -- Wait for the connection to be established
      Tcp_Wait_For_Events (Sock, SOCKET_EVENT_CONNECTED or SOCKET_EVENT_CLOSED,
                           Sock.S_Timeout, Event);

      -- Connection successfully established?
      if Event = SOCKET_EVENT_CONNECTED then
         ERROR := NO_ERROR;

      -- Failed to establish connection?
      elsif Event = SOCKET_EVENT_CLOSED then
         ERROR := ERROR_CONNECTION_FAILED;
      
      -- Timeout exception?
      else
         ERROR := ERROR_TIMEOUT;
      end if;
   end Tcp_Connect;


   ----------------
   -- Tcp_Listen --
   ----------------

   procedure Tcp_Listen
      (Sock    : in out Not_Null_Socket;
       Backlog :        unsigned)
       -- Error   :    out Error_T)
   is
   begin
      -- Socket already connected?
      -- if Sock.State /= TCP_STATE_CLOSED then
      --    Error := ERROR_ALREADY_CONNECTED;
      --    return;
      -- end if;

      -- Set the size of the SYN queue Limit the number of pending connections
      if Backlog > 0 then
         Sock.synQueueSize := unsigned'Min (Backlog, TCP_MAX_SYN_QUEUE_SIZE);
      else
         Sock.synQueueSize :=
           unsigned'Min (TCP_DEFAULT_SYN_QUEUE_SIZE, TCP_MAX_SYN_QUEUE_SIZE);
      end if;

      -- Place the socket in the listening state
      Tcp_Change_State (Sock, TCP_STATE_LISTEN);

      -- Sucessful processing
      -- Error := NO_ERROR;
   end Tcp_Listen;


   ----------------
   -- Tcp_Accept --
   ----------------

   procedure Tcp_Accept
      (Sock           : in out Not_Null_Socket;
       Client_Ip_Addr :    out IpAddr;
       Client_Port    :    out Port;
       Client_Socket  :    out Socket)
   is
      procedure Mem_Pool_Free 
         (Queue_Item : in out Tcp_Syn_Queue_Item_Acc)
         with
            Import => True,
            Convention => C,
            External_Name => "memPoolFree",
            Post => Queue_Item = null,
            Global => null;

      Error : Error_T;
      Queue_Item : Tcp_Syn_Queue_Item_Acc;
   begin

      Os_Acquire_Mutex (Net_Mutex);

      -- Initialization of out variables
      Client_Ip_Addr := (Ip => (others => 0),
                         Length => 0);
      Client_Port := 0;
      Client_Socket := null;

      -- Wait for an connection attempt
      loop
         -- The SYN queue is empty ?
         if Sock.synQueue = null then
            -- Set the events the application is interested in
            Sock.S_Event_Mask := SOCKET_EVENT_RX_READY;
            -- Reset the event object
            Os_Reset_Event (Sock.S_Event);

            -- Release exclusive access
            Os_Release_Mutex (Net_Mutex);
            -- Wait until a SYN message is received from a client
            Os_Wait_For_Event (Sock.S_Event, Sock.S_Timeout);
            -- Get exclusive access
            Os_Acquire_Mutex (Net_Mutex);
         end if;

         -- Check whether the queue is still empty
         if Sock.synQueue = null then
            -- Timeout error
            Client_Socket := null;
            -- Exit immediately
            exit;
         end if;

         -- Point to the first item in the SYN queue
         Queue_Item := Sock.synQueue;

         -- Return the client IP address and port number
         Client_Ip_Addr := Queue_Item.Src_Addr;
         Client_Port    := Queue_Item.Src_Port;

         -- Release exclusive access
         Os_Release_Mutex (Net_Mutex);
         -- Create a new socket to handle the incoming connection request
         Socket_Open (Client_Socket, SOCKET_TYPE_STREAM, SOCKET_IP_PROTO_TCP);
         -- Get exclusive access
         Os_Acquire_Mutex (Net_Mutex);

         -- Socket successfully created?
         if Client_Socket /= null then
            -- The user owns the socket;
            Client_Socket.owned_Flag := True; 

            -- Inherit settings from the listening socket
            Client_Socket.txBufferSize := Sock.txBufferSize;
            Client_Socket.rxBufferSize := Sock.rxBufferSize;

            -- Allocate transmit buffer
            Net_Tx_Buffer_Set_Length 
                  (Client_Socket.txBuffer,
                   Client_Socket.txBufferSize,
                   Error);
            
            -- Check status code
            if Error = NO_ERROR then
               -- Allocate receive buffer
               Net_Rx_Buffer_Set_Length 
                  (Client_Socket.rxBuffer,
                   Client_Socket.rxBufferSize,
                   Error);
            end if;

            -- Transmit and receive buffers successfully allocated?
            if Error = NO_ERROR then
               -- Bind the newly created socket to the appropriate interface
               Client_Socket.S_Net_Interface := Queue_Item.Net_Interface;

               -- Bind the socket to the specified address
               Client_Socket.S_localIpAddr := Queue_Item.Dest_Addr;
               Client_Socket.S_Local_Port := Sock.S_Local_Port;
               -- Save the port number and the IP address of the remote host
               Client_Socket.S_remoteIpAddr := Queue_Item.Src_Addr;
               Client_Socket.S_Remote_Port := Queue_Item.Src_Port;

               -- The SMSS is the size of the largest segment that the sender
               -- can transmit
               Client_Socket.smss := Queue_Item.mss;

               -- The RMSS is the size of the largest segment the receiver is
               -- willing to accept
               Client_Socket.rmss := unsigned_short'Min
                     (unsigned_short(Client_Socket.rxBufferSize),
                      TCP_MAX_MSS);
               
               -- Initialize TCP control block
               Client_Socket.iss     := netGetRand;
               Client_Socket.irs     := Queue_Item.Isn;
               Client_Socket.sndUna  := Client_Socket.iss;
               Client_Socket.sndNxt  := Client_Socket.iss + 1;
               Client_Socket.rcvNxt  := Client_Socket.irs + 1;
               Client_Socket.rcvUser := 0;
               Client_Socket.rcvWnd  := unsigned_short(Client_Socket.rxBufferSize);

               -- Default retransmission timeout
               Client_Socket.rto := TCP_INITIAL_RTO;

               -- Default congestion state
               Sock.congestState := TCP_CONGEST_STATE_IDLE;
               -- Initial congestion window
               Client_Socket.cwnd := unsigned_short(unsigned_long'Min 
                        (unsigned_long(TCP_INITIAL_WINDOW * Client_Socket.smss),
                         unsigned_long(Client_Socket.txBufferSize)));
               -- Slow start threshold should be set arbitrarily high
               Client_Socket.ssthresh := unsigned_short'Last;
               -- Recover is set to the initial send sequence number
               Client_Socket.recover := Client_Socket.iss;

               -- Send a SYN ACK control segment
               Tcp_Send_Segment 
                  (Sock         => Client_Socket,
                   Flags        => TCP_FLAG_SYN or TCP_FLAG_ACK,
                   Seq_Num      => Client_Socket.iss,
                   Ack_Num      => Client_Socket.rcvNxt,
                   Length       => 0,
                   Add_To_Queue => True,
                   Error        => Error);

               -- TCP segment successfully sent?
               if Error = NO_ERROR then
                  -- Remove the item from the SYN queue
                  Sock.synQueue := Queue_Item.Next;
                  -- Deallocate memory buffer
                  Queue_Item.Next := null;
                  Mem_Pool_Free (Queue_Item);
                  -- Update the state of events
                  Tcp_Update_Events (Sock);

                  -- The connection state should be change to SYN-RECEIVED
                  Tcp_Change_State (Sock, TCP_STATE_SYN_RECEIVED);

                  -- We are done...
                  exit;
               end if;
            end if;

            -- Dispose the socket
            Tcp_Abort (Client_Socket, Error);
         end if;

         -- Remove the item from the SYN queue
         Sock.synQueue := Queue_Item.Next;
         -- Deallocate memory buffer
         Queue_Item.Next := null;
         Mem_Pool_Free (Queue_Item);

         -- Wait for the next connection attempt
      end loop;

      -- Release exclusive access
      Os_Release_Mutex (Net_Mutex);
   end Tcp_Accept;

   
   ---------------
   -- Tcp_Abord --
   ---------------

   procedure Tcp_Abort
      (Sock  : in out Not_Null_Socket;
       Error :    out Error_T)
   is
   begin
      case Sock.State is
         -- SYN-RECEIVED, ESTABLISHED, FIN-WAIT-1
         -- FIN-WAIT-2 or CLOSE-WAIT state?
         when TCP_STATE_SYN_RECEIVED
               | TCP_STATE_ESTABLISHED
               | TCP_STATE_FIN_WAIT_1
               | TCP_STATE_FIN_WAIT_2
               | TCP_STATE_CLOSE_WAIT =>
            -- Send a reset segment
            Tcp_Send_Segment (Sock, TCP_FLAG_RST, Sock.sndNxt, 0, 0, False, Error);
            -- Enter CLOSED state
            Tcp_Change_State (Sock, TCP_STATE_CLOSED);
            -- Delete TCB
            Tcp_Delete_Control_Block (Sock);
            -- Mark the socket as closed
            Sock.S_Type := SOCKET_TYPE_UNUSED;

         -- TIME-WAIT state?
         when TCP_STATE_TIME_WAIT =>
            -- The user doe not own the socket anymore...
            Sock.owned_Flag := False;
            -- TCB will be deleted and socket will be closed
            -- when the 2MSL timer will elapse
            Error := NO_ERROR;

         -- Any other state?
         when others =>
            -- Enter CLOSED state
            Tcp_Change_State (Sock, TCP_STATE_CLOSED);
            --Delete TCB
            Tcp_Delete_Control_Block (Sock);
            -- Mark the socket as closed
            Sock.S_Type := SOCKET_TYPE_UNUSED;
            -- No error to report
            Error := NO_ERROR;
      end case;
   end Tcp_Abort;


   --------------
   -- Tcp_Send --
   --------------

   procedure Tcp_Send
      (Sock    : in out Not_Null_Socket;
       Data    :        char_array;
       Written :    out Integer;
       Flags   :        unsigned;
       Error   :    out Error_T)
   is
      -- Actual number of bytes written Total_Length : Natural := 0; Event :
      -- unsigned; n : unsigned;
   begin
      -- -- Check whether the socket is in the listening state if Sock.State /=
      -- TCP_STATE_LISTEN then
      --     Error := ERROR_NOT_CONNECTED;
      -- end if;

      -- -- Send as much as possible loop
      --     -- Wait until there is more room in the send buffer
      --     Tcp_Wait_For_Events (Sock, SOCKET_EVENT_TX_READY'Enum_Rep, Sock.S_Timeout, Event);
      --     if Event /= SOCKET_EVENT_TX_READY'Enum_Rep then
      --         Error := ERROR_TIMEOUT;
      --     end if;

      --     -- Check current TCP state
      --     case Sock.State is
      --         when TCP_STATE_ESTABLISHED | TCP_STATE_CLOSE_WAIT =>
      --             -- The send buffer is now available for writing
      --             null;
      --         when TCP_STATE_LAST_ACK | TCP_STATE_FIN_WAIT_1
      --             | TCP_STATE_FIN_WAIT_2 | TCP_STATE_CLOSING
      --             | TCP_STATE_TIME_WAIT =>
      --             Error := ERROR_CONNECTION_CLOSING;
      --             return;

      --         -- CLOSED state ?
      --         when others =>
      --             -- The connection was reset by remote side?
      --             if Sock.reset_Flag /= 0 then
      --                 Error := ERROR_CONNECTION_RESET;
      --             else
      --                 Error := ERROR_NOT_CONNECTED;
      --             end if;
      --             return;
      --     end case;

      --     -- Determine the actual number of bytes in the send buffer
      --     n := Sock.sndUser + Sock.sndNxt - Sock.sndUna;

   --     -- Exit immediately if the transmission buffer is full (sanity check)
      --     if n >= Sock.txBufferSize then
      --         Error := ERROR_FAILURE;
      --         return;
      --     end if;

      --     -- Number of bytes available for writing
      --     n := Sock.txBufferSize - n;
      --     -- Calculate the number of bytes to copy at a time
      --     n := unsigned'Min(n, Data'Length - Total_Length);

      --     -- Any Data to copy
      --     if n > 0 then
      --         -- Copy user data to send buffer
   --         Tcp_Write_Tx_Buffer(Sock, Sock.sndNxt + Sock.sndUser, Data, n);

      --         -- Update the number of data buffered but not yet sent
      --         Sock.sndUser := Sock.sndUser + n;

      --     end if;

      -- exit when Total_Length < Data'Length; end loop;

      Tcp_Binding.Tcp_Send (Sock, Data, Written, Flags, Error);
   end Tcp_Send;


   -----------------
   -- Tcp_Receive --
   -----------------

   procedure Tcp_Receive
      (Sock     : in out Not_Null_Socket;
       Data     :    out char_array;
       Received :    out unsigned;
       Flags    :        unsigned;
       Error    :    out Error_T)
   is begin
      Tcp_Binding.Tcp_Receive (Sock, Data, Received, Flags, Error);
   end Tcp_Receive;


   --------------------------------
   -- Tcp_Kill_Oldest_Connection --
   --------------------------------

   procedure Tcp_Kill_Oldest_Connection (Sock : out Socket) is
      Time     : constant Systime := Os_Get_System_Time;
      Aux_Sock : Socket;
   begin
      Sock := null;
      for I in Socket_Table'Range loop
         Get_Socket_From_Table (I, Aux_Sock);

         if Aux_Sock.S_Type = SOCKET_TYPE_STREAM then
            if Aux_Sock.State = TCP_STATE_TIME_WAIT then
               -- Keep track of the oldest socket in the TIME-WAIT state
               if Sock = null then
                  -- Save socket handle
                  -- Sock := Aux_Sock;
                  -- It's to prevent SPARK to see that Sock and Aux_Sock
                  -- are aliased
                  Get_Socket_From_Table (I, Sock);
               end if;

               if (Time - Aux_Sock.timeWaitTimer.startTime) >
                 (Time - Sock.timeWaitTimer.startTime)
               then
                  Sock := Aux_Sock;
               end if;
            end if;
         end if;
      end loop;

      -- Any connection in the TIME-WAIT state?
      if Sock /= null then
         -- Enter CLOSED state
         Tcp_Change_State (Sock, TCP_STATE_CLOSED);
         -- Delete TCB
         Tcp_Delete_Control_Block (Sock);
         -- Mark the socket as closed
         Sock.S_Type := SOCKET_TYPE_UNUSED;
      end if;
   end Tcp_Kill_Oldest_Connection;


   -------------------
   -- Tcp_Get_State --
   -------------------

   procedure Tcp_Get_State
      (Sock  : in     Not_Null_Socket;
       State :    out Tcp_State)
   is
   begin
      Os_Acquire_Mutex (Net_Mutex);
      State := Sock.State;
      Os_Release_Mutex (Net_Mutex);
   end Tcp_Get_State;


   ------------------
   -- Tcp_Shutdown --
   ------------------

   procedure Tcp_Shutdown
      (Sock  : in out Not_Null_Socket;
       How   :        Socket_Shutdown_Flags;
       Error :    out Error_T)
   is
      Written : Integer;
      Event : Socket_Event;
      Buf : char_array(0..0) := (others => nul); -- @TODO Buf should be NULL here
   begin

      -- Disable transmission?
      if How = SOCKET_SD_SEND or How = SOCKET_SD_BOTH then
         -- Check current state
         case Sock.State is
            when TCP_STATE_CLOSED | TCP_STATE_LISTEN =>
               -- The connection does not exist
               Error := ERROR_NOT_CONNECTED;
               return;
            
            when TCP_STATE_SYN_RECEIVED | TCP_STATE_ESTABLISHED =>
               -- Flush the send buffer
               Tcp_Send (Sock, Buf, Written, SOCKET_FLAG_NO_DELAY, Error);
               if Error /= NO_ERROR then
                  return;
               end if;

               -- Make sure all the data has been sent out
               Tcp_Wait_For_Events 
                  (Sock       => Sock,
                   Event_Mask => SOCKET_EVENT_TX_DONE,
                   Timeout    => Sock.S_Timeout,
                   Event      => Event);
               
               -- Timeout error?
               if event /= SOCKET_EVENT_TX_DONE then
                  Error := ERROR_TIMEOUT;
                  return;
               end if;

               -- Send a FIN segment
               Tcp_Send_Segment 
                  (Sock         => Sock,
                   Flags        => TCP_FLAG_FIN or TCP_FLAG_ACK,
                   Seq_Num      => Sock.sndNxt,
                   Ack_Num      => Sock.rcvNxt,
                   Length       => 0, 
                   Add_To_Queue => True,
                   Error        => Error);

               -- Failed to send FIN segment?
               if Error /= NO_ERROR then
                  return;
               end if;

               -- Sequence number expected to be received
               Sock.sndNxt := Sock.sndNxt + 1;
               -- Switch to the FIN-WAIT1 state
               Tcp_Change_State (Sock, TCP_STATE_FIN_WAIT_1);

               -- Wait for the FIN to be acknowledged
               Tcp_Wait_For_Events (
                  Sock       => Sock,
                  Event_Mask => SOCKET_EVENT_TX_SHUTDOWN,
                  Timeout    => Sock.S_Timeout,
                  Event      => Event);
               
               -- Timeout interval elapsed?
               if event /= SOCKET_EVENT_TX_SHUTDOWN then
                  Error := ERROR_TIMEOUT;
                  return;
               end if;
               -- Continue processing

            when TCP_STATE_CLOSE_WAIT =>
               -- Flush the send buffer
               Tcp_Send (Sock, Buf, Written, SOCKET_FLAG_NO_DELAY, Error);
               if Error /= NO_ERROR then
                  return;
               end if;

               -- Make sure all the data has been sent out
               Tcp_Wait_For_Events 
                  (Sock       => Sock,
                   Event_Mask => SOCKET_EVENT_TX_DONE,
                   Timeout    => Sock.S_Timeout,
                   Event      => Event);
               
               -- Timeout error?
               if event /= SOCKET_EVENT_TX_DONE then
                  Error := ERROR_TIMEOUT;
                  return;
               end if;

               -- Send a FIN segment
               Tcp_Send_Segment 
                  (Sock         => Sock,
                   Flags        => TCP_FLAG_FIN or TCP_FLAG_ACK,
                   Seq_Num      => Sock.sndNxt,
                   Ack_Num      => Sock.rcvNxt,
                   Length       => 0, 
                   Add_To_Queue => True,
                   Error        => Error);

               -- Failed to send FIN segment?
               if Error /= NO_ERROR then
                  return;
               end if;

               -- Sequence number expected to be received
               Sock.sndNxt := Sock.sndNxt + 1;
               -- Switch to the FIN-WAIT1 state
               Tcp_Change_State (Sock, TCP_STATE_LAST_ACK);

               -- Wait for the FIN to be acknowledged
               Tcp_Wait_For_Events (
                  Sock       => Sock,
                  Event_Mask => SOCKET_EVENT_TX_SHUTDOWN,
                  Timeout    => Sock.S_Timeout,
                  Event      => Event);
               
               -- Timeout interval elapsed?
               if event /= SOCKET_EVENT_TX_SHUTDOWN then
                  Error := ERROR_TIMEOUT;
                  return;
               end if;
               -- Continue processing

            when TCP_STATE_FIN_WAIT_1 | TCP_STATE_CLOSING
                  | TCP_STATE_LAST_ACK =>
               -- Wait for the FIN to be acknowledged
               Tcp_Wait_For_Events (
                  Sock       => Sock,
                  Event_Mask => SOCKET_EVENT_TX_SHUTDOWN,
                  Timeout    => Sock.S_Timeout,
                  Event      => Event);
               -- Timeout interval elapsed?
               if Event /= SOCKET_EVENT_TX_SHUTDOWN then
                  Error := ERROR_TIMEOUT;
                  return;
               end if;

               -- Continue processing
            
            when others =>
               -- Nothing to do
               -- Continue processing
               null;
         end case;
      end if;

      -- Disable reception?
      if How = SOCKET_SD_RECEIVE or How = SOCKET_SD_BOTH then

         -- Check current state
         case Sock.State is
            when TCP_STATE_LISTEN =>
               -- The connection does not exist 
               Error := ERROR_NOT_CONNECTED;
               return;

            when TCP_STATE_SYN_SENT | TCP_STATE_SYN_RECEIVED
                  | TCP_STATE_ESTABLISHED | TCP_STATE_FIN_WAIT_1
                  | TCP_STATE_FIN_WAIT_2 =>
               -- Wait for the FIN to be acknowledged
               Tcp_Wait_For_Events (
                  Sock       => Sock,
                  Event_Mask => SOCKET_EVENT_TX_SHUTDOWN,
                  Timeout    => Sock.S_Timeout,
                  Event      => Event);
               -- Timeout interval elapsed?
               if Event /= SOCKET_EVENT_TX_SHUTDOWN then
                  Error := ERROR_TIMEOUT;
                  return;
               end if;
            
            when others =>
               -- A FIN segment has already been received
               null;
         end case;
      end if;

      -- Sucessful operation
      Error := NO_ERROR;
   end Tcp_Shutdown;

end Tcp_Interface;
