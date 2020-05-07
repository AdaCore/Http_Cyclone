with System;
with Tcp_Misc_Binding; use Tcp_Misc_Binding;
with Socket_Helper;    use Socket_Helper;
with Os;               use Os;

package body Tcp_Binding with
   SPARK_Mode => Off
is

   procedure Tcp_Get_Dynamic_Port (P : out Port) is
      function netGetRand return unsigned with
         Import        => True,
         Convention    => C,
         External_Name => "netGetRand";

   begin
      -- Retrieve current port number
      P := Tcp_Dynamic_Port;
      -- Invalid port number?
      if P < SOCKET_EPHEMERAL_PORT_MIN or P > SOCKET_EPHEMERAL_PORT_MAX then
         P :=
           SOCKET_EPHEMERAL_PORT_MIN +
           Port
             (netGetRand mod
              unsigned
                (SOCKET_EPHEMERAL_PORT_MAX - SOCKET_EPHEMERAL_PORT_MIN + 1));
      end if;

      if P < SOCKET_EPHEMERAL_PORT_MAX then
         Tcp_Dynamic_Port := P + 1;
      else
         Tcp_Dynamic_Port := SOCKET_EPHEMERAL_PORT_MIN;
      end if;
   end Tcp_Get_Dynamic_Port;

   procedure Tcp_Connect
      (Sock           : in out Socket;
       Remote_Ip_Addr :        IpAddr;
       Remote_Port    :        Port;
       Error          :    out Error_T)
   is
      function tcpConnect
        (Sock         : Socket;
         remoteIpAddr : System.Address;
         remotePort   : Port)
         return unsigned with
         Import        => True,
         Convention    => C,
         External_Name => "tcpConnect";
   begin
      Error :=
        Error_T'Enum_Val
          (tcpConnect (Sock, Remote_Ip_Addr'Address, Remote_Port));
   end Tcp_Connect;

   procedure Tcp_Listen
      (Sock    : in out Socket;
       Backlog :        unsigned;
       Error   :    out Error_T)
   is
   begin
      -- Socket already connected?
      if Sock.State /= TCP_STATE_CLOSED then
         Error := ERROR_ALREADY_CONNECTED;
         return;
      end if;

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
      Error := NO_ERROR;
   end Tcp_Listen;

   procedure Tcp_Accept
      (Sock           : in out Socket;
       Client_Ip_Addr :    out IpAddr;
       Client_Port    :    out Port;
       Client_Socket  :    out Socket)
   is
      function tcpAccept
        (Sock           : in out Socket;
         Client_Ip_Addr :    out IpAddr;
         P              :    out Port)
         return Socket with
         Import        => True,
         Convention    => C,
         External_Name => "tcpAccept";
   begin
      Client_Socket := tcpAccept (Sock, Client_Ip_Addr, Client_Port);
   end Tcp_Accept;

   procedure Tcp_Abort
      (Sock  : in out Socket;
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
            Tcp_Send_Segment
               (Sock, uint8(TCP_FLAG_RST'Enum_Rep), Sock.sndNxt, 0, 0, 0, Error);
            -- Enter CLOSED state
            Tcp_Change_State (Sock, TCP_STATE_CLOSED);
            -- Delete TCB
            Tcp_Delete_Control_Block (Sock);
            -- Mark the socket as closed
            Sock.S_Type := SOCKET_TYPE_UNUSED'Enum_Rep;

         -- TIME-WAIT state?
         when TCP_STATE_TIME_WAIT =>
            -- The user doe not own the socket anymore...
            Sock.owned_Flag := 0;
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
            Sock.S_Type := SOCKET_TYPE_UNUSED'Enum_Rep;
            -- No error to report
            Error := NO_ERROR;
      end case;
   end Tcp_Abort;

   procedure Tcp_Send
      (Sock    : in out Socket;
       Data    :        char_array;
       Written :    out Integer;
       Flags   :        unsigned;
       Error   :    out Error_T)
   is
      -- Actual number of bytes written Total_Length : Natural := 0; Event :
      -- unsigned; n : unsigned;

      function tcpSend
        (Sock    :     Socket;
         Data    :     char_array;
         Length  :     unsigned;
         Written : out unsigned;
         Flags   :     unsigned)
         return unsigned with
         Import        => True,
         Convention    => C,
         External_Name => "tcpSend";

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

      Error :=
        Error_T'Enum_Val
          (tcpSend (Sock, Data, Data'Length, unsigned (Written), Flags));
   end Tcp_Send;

   procedure Tcp_Receive
      (Sock     : in out Socket;
       Data     :    out char_array;
       Received :    out unsigned;
       Flags    :        unsigned;
       Error    :    out Error_T)
   is
      function tcpReceive
        (Sock     :     Socket;
         Data     : out char_array;
         Size     :     unsigned;
         Received : out unsigned;
         Flags    :     unsigned)
         return unsigned with
         Import        => True,
         Convention    => C,
         External_Name => "tcpReceive";
   begin
      Error :=
        Error_T'Enum_Val
          (tcpReceive (Sock, Data, Data'Length, Received, Flags));
   end Tcp_Receive;

   procedure Tcp_Kill_Oldest_Connection (Sock : out Socket) is
      Time     : Systime := Os_Get_System_Time;
      Aux_Sock : Socket  := null;
   begin
      Sock := null;
      for I in Socket_Table'Range loop
         Get_Socket_From_Table (I, Aux_Sock);

         if Aux_Sock.S_Type = SOCKET_TYPE_STREAM'Enum_Rep then
            if Aux_Sock.State = TCP_STATE_TIME_WAIT then
               -- Keep track of the oldest socket in the TIME-WAIT state
               if Sock = null then
                  -- Save socket handle
                  Sock := Aux_Sock;
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
         Sock.S_Type := SOCKET_TYPE_UNUSED'Enum_Rep;
      end if;
   end Tcp_Kill_Oldest_Connection;

   procedure Tcp_Get_State
      (Sock  :     Socket;
       State : out Tcp_State)
   is
   begin
      Os_Acquire_Mutex (Net_Mutex);
      State := Sock.State;
      Os_Release_Mutex (Net_Mutex);
   end Tcp_Get_State;

   procedure Tcp_Shutdown
      (Sock  : in out Socket;
       How   :        unsigned;
       Error :    out Error_T)
   is
      function tcpShutdown
        (Sock : Socket;
         how  : unsigned)
         return unsigned
        with
          Import        => True,
          Convention    => C,
          External_Name => "tcpShutdown";
   begin
      Error := Error_T'Enum_Val (tcpShutdown (Sock, How));
   end Tcp_Shutdown;

end Tcp_Binding;
