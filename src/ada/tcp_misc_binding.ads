pragma Unevaluated_Use_Of_Old (Allow);
pragma Ada_2020;

with Common_Type;  use Common_Type;
with Error_H;      use Error_H;
with Interfaces.C; use Interfaces.C;
with Socket_Types; use Socket_Types;
with Tcp_Type;     use Tcp_Type;

package Tcp_Misc_Binding with
   SPARK_Mode
is

   procedure Tcp_Change_State
      (Sock      : in out Not_Null_Socket;
       New_State : in     Tcp_State)
      with
        Depends => (Sock =>+ New_State),
        Post =>
            (if New_State = TCP_STATE_CLOSED then
               (if Sock.State'Old = TCP_STATE_LAST_ACK or else
                   Sock.State'Old = TCP_STATE_TIME_WAIT
               then
                  Model(Sock) = (Model(Sock)'Old with delta
                              S_State => TCP_STATE_CLOSED)
               else
                  Model(Sock) = (Model(Sock)'Old with delta
                              S_State => TCP_STATE_CLOSED,
                              S_Reset_Flag => True)
               )
            else
               Model(Sock) = (Model(Sock)'Old with delta
                           S_State => New_State));

   procedure Tcp_Wait_For_Events
      (Sock       : in out Not_Null_Socket;
       Event_Mask : in     Socket_Event;
       Timeout    : in     Systime;
       Event      :    out Socket_Event)
      with
         Depends =>
           (Sock  =>+ (Event_Mask, Timeout),
            Event =>  (Event_Mask, Timeout)),
         Pre  => -- Only one of the listed event in Event_Mask may complete the wait
                 -- @TODO It should be a precondition to avoid incorrect use of the function
                 -- (Sock.S_Event_Flags and Event_Mask) = 2^k
                 Event_Mask /= 0,
         Post =>
            Basic_Model(Sock) = Basic_Model(Sock)'Old and then

            -- If Event is SOCKET_EVENT_CONNECTED
            (if (Event_Mask and SOCKET_EVENT_CONNECTED) /= 0 then
               (if Event = SOCKET_EVENT_CONNECTED then
                  (if Sock.State'Old = TCP_STATE_SYN_SENT then
                     Model(Sock) = (Model(Sock)'Old with delta
                           S_State => TCP_STATE_ESTABLISHED) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                           S_State => TCP_STATE_CLOSE_WAIT))))

            and then
            (if (Event_Mask and SOCKET_EVENT_CLOSED) /= 0 then
               (if Event = SOCKET_EVENT_CLOSED then
                  (if Sock.State'Old = TCP_STATE_SYN_SENT then
                     Model(Sock) = Model(Sock)'Old'Update
                        (S_State => TCP_STATE_CLOSED,
                         S_Reset_Flag => True))))

            and then
            (if (Event_Mask and SOCKET_EVENT_TX_READY) /=0 then
               (if Sock.State'Old = TCP_STATE_CLOSED then
                  Event = SOCKET_EVENT_TX_READY and then
                  Model(Sock) = Model(Sock)'Old) and then
               (if Event = SOCKET_EVENT_TX_READY then
                  (if Sock.State'Old = TCP_STATE_CLOSE_WAIT then
                     Model (Sock) = Model (Sock)'Old or else
                     -- If a RST has been received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_CLOSED then
                     Model (Sock) = Model (Sock)'Old
                  elsif Sock.State'Old in TCP_STATE_SYN_SENT
                                        | TCP_STATE_SYN_RECEIVED
                                        | TCP_STATE_ESTABLISHED
                  then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_ESTABLISHED) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSE_WAIT) or else
                     -- If a RST has been received
                     Model(Sock) = (Model (Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True))))

            and then
            (if (Event_Mask and SOCKET_EVENT_RX_READY) /= 0 then
               (if Event = SOCKET_EVENT_RX_READY then
                  (if Sock.State'Old in TCP_STATE_ESTABLISHED
                                       | TCP_STATE_SYN_RECEIVED
                                       | TCP_STATE_SYN_SENT
                  then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_ESTABLISHED) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSE_WAIT) or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_FIN_WAIT_1 then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_FIN_WAIT_1) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_FIN_WAIT_2) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSING) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     -- RST segment received or the connection has been
                     -- properly closed
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => False)
                  elsif Sock.State'Old = TCP_STATE_FIN_WAIT_2 then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_FIN_WAIT_2) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     -- RST segment received or the connection has been
                     -- properly closed
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => False)
                  elsif  Sock.State'Old in TCP_STATE_CLOSE_WAIT
                                         | TCP_STATE_CLOSING
                                         | TCP_STATE_TIME_WAIT
                                         | TCP_STATE_LAST_ACK
                  then
                     -- Nothing happen. The result is the same.
                     Model(Sock) = Model(Sock)'Old
                  elsif Sock.State'Old = TCP_STATE_CLOSED then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_Reset_Flag => Sock.reset_Flag'Old))))

            and then
            (if (Event_Mask and SOCKET_EVENT_TX_ACKED) /= 0 then
               (if Event = SOCKET_EVENT_TX_ACKED then
                  -- @TODO : To be continued if needed
                  (if Sock.State'Old = TCP_STATE_ESTABLISHED then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_ESTABLISHED) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSE_WAIT) or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_CLOSE_WAIT then
                     Model(Sock) = Model(Sock)'Old or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True))))

            and then
            (if (Event_Mask and SOCKET_EVENT_TX_DONE) /= 0 then
               (if Event = SOCKET_EVENT_TX_DONE then
                  (if Sock.State'Old in TCP_STATE_CLOSED
                                      | TCP_STATE_SYN_SENT
                                      | TCP_STATE_SYN_RECEIVED
                                      | TCP_STATE_FIN_WAIT_1
                                      | TCP_STATE_FIN_WAIT_2
                                      | TCP_STATE_TIME_WAIT
                  then
                     Model(Sock) = Model(Sock)'Old
                  elsif Sock.State'Old = TCP_STATE_CLOSING then
                     Model(Sock) = Model(Sock)'Old or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_LAST_ACK then
                     Model(Sock) = Model(Sock)'Old or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED)
                  elsif Sock.State'Old = TCP_STATE_CLOSE_WAIT then
                     Model(Sock) = Model(Sock)'Old or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_ESTABLISHED then
                     Model(Sock) = Model(Sock)'Old or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSE_WAIT) or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True))))

            and then
            (if (Event_Mask and SOCKET_EVENT_TX_SHUTDOWN) /= 0 then
               (if Event = SOCKET_EVENT_TX_SHUTDOWN then
                  (if Sock.State'Old = TCP_STATE_FIN_WAIT_1 then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_FIN_WAIT_2) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_CLOSING then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_CLOSE_WAIT then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_LAST_ACK then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED))))

            and then
            (if (Event_Mask and SOCKET_EVENT_RX_SHUTDOWN) /= 0 then
               (if Event = SOCKET_EVENT_RX_SHUTDOWN then
                  (if Sock.State'Old in TCP_STATE_SYN_RECEIVED
                                      | TCP_STATE_SYN_SENT
                                      | TCP_STATE_ESTABLISHED
                  then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_ESTABLISHED) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSE_WAIT) or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_LAST_ACK then
                     Model(Sock) = Model(Sock)'Old
                  elsif Sock.State'Old = TCP_STATE_FIN_WAIT_1 then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSING) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_FIN_WAIT_2 then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_CLOSED then
                     Model(Sock) = Model(Sock)'Old)));

   procedure Tcp_Write_Tx_Buffer
      (Sock    : Not_Null_Socket;
       Seq_Num : unsigned;
       Data    : Send_Buffer;
       Length  : unsigned)
      with
        Global => null,
        Import        => True,
        Convention    => C,
        External_Name => "tcpWriteTxBuffer",
        Post => Model(Sock) = Model(Sock)'Old;

   procedure Tcp_Read_Rx_Buffer
      (Sock    :     Not_Null_Socket;
       Seq_Num :     unsigned;
       Data    : out Received_Buffer;
       Length  :     unsigned)
      with
        Global => null,
        Import => True,
        Convention => C,
        External_Name => "tcpReadRxBuffer",
        Pre => Data'First <= Data'Last,
        Post =>
            Data(Data'First .. Data'Last)'Initialized and then
            Model (Sock) = Model(Sock)'Old;

   procedure Tcp_Delete_Control_Block
      (Sock : Not_Null_Socket)
      with
        Import        => True,
        Convention    => C,
        External_Name => "tcpDeleteControlBlock",
        Global        => null,
        Post => -- Change the Post condition to consider the TCB
            Model (Sock) = Model (Sock)'Old;

   procedure Tcp_Send_Segment
      (Sock         : in out Not_Null_Socket;
       Flags        :        uint8;
       Seq_Num      :        unsigned;
       Ack_Num      :        unsigned;
       Length       :        unsigned_long;
       Add_To_Queue :        Bool;
       Error        :    out Error_T)
      with
        Depends =>
            (Sock  =>+ (Flags, Seq_Num, Ack_Num, Length, Add_To_Queue),
             Error =>  (Sock, Flags, Seq_Num, Ack_Num, Length, Add_To_Queue)),
        Post =>
            (if Error = NO_ERROR then
               Model (Sock) = Model(Sock)'Old
             else
               Basic_Model (Sock) = Basic_Model (Sock)'Old);

   procedure Tcp_Update_Events
      (Sock : Not_Null_Socket)
      with
         Global => null,
         Post => Model(Sock) = Model(Sock)'Old and then
                 Sock.S_Event_Mask = Sock.S_Event_Mask'Old,
         Pre =>
            -- Valid entries.
            Sock.S_Event_Mask = SOCKET_EVENT_TIMEOUT or else
            Sock.S_Event_Mask = SOCKET_EVENT_CONNECTED or else
            Sock.S_Event_Mask = SOCKET_EVENT_CLOSED or else
            Sock.S_Event_Mask = SOCKET_EVENT_TX_READY or else
            Sock.S_Event_Mask = SOCKET_EVENT_TX_DONE or else
            Sock.S_Event_Mask = SOCKET_EVENT_TX_ACKED or else
            Sock.S_Event_Mask = SOCKET_EVENT_TX_SHUTDOWN or else
            Sock.S_Event_Mask = SOCKET_EVENT_RX_READY or else
            Sock.S_Event_Mask = SOCKET_EVENT_RX_SHUTDOWN or else
            Sock.S_Event_Mask = (SOCKET_EVENT_CONNECTED or SOCKET_EVENT_CLOSED),
         Contract_Cases => (
            Sock.State = TCP_STATE_ESTABLISHED =>
               (Sock.S_Event_Flags and SOCKET_EVENT_CLOSED) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_TX_SHUTDOWN) = 0 and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_CONNECTED) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_CONNECTED),

            Sock.State = TCP_STATE_CLOSED =>
               (Sock.S_Event_Flags and SOCKET_EVENT_CONNECTED) = 0 and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_CLOSED) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_CLOSED) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_TX_READY) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_TX_READY) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_TX_DONE) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_TX_DONE) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_TX_ACKED) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_TX_ACKED) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_TX_SHUTDOWN) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_TX_SHUTDOWN) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_RX_READY) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_RX_READY) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_RX_SHUTDOWN) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_RX_SHUTDOWN),

            Sock.State = TCP_STATE_SYN_SENT =>
               (Sock.S_Event_Flags and SOCKET_EVENT_CONNECTED) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_CLOSED) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_TX_READY) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_TX_SHUTDOWN) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_RX_READY) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_RX_SHUTDOWN) = 0 and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_TX_DONE) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_TX_DONE) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_TX_ACKED) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_TX_ACKED),

            Sock.State = TCP_STATE_SYN_RECEIVED =>
               (Sock.S_Event_Flags and SOCKET_EVENT_CONNECTED) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_CLOSED) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_TX_READY) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_TX_SHUTDOWN) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_RX_READY) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_RX_SHUTDOWN) = 0 and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_TX_DONE) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_TX_DONE) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_TX_ACKED) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_TX_ACKED),

            Sock.State = TCP_STATE_FIN_WAIT_1 =>
               (Sock.S_Event_Flags and SOCKET_EVENT_CLOSED) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_TX_SHUTDOWN) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_RX_SHUTDOWN) = 0 and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_CONNECTED) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_CONNECTED) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_TX_READY) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_TX_READY) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_TX_DONE) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_TX_DONE) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_TX_ACKED) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_TX_ACKED),

            Sock.State = TCP_STATE_FIN_WAIT_2 =>
               (Sock.S_Event_Flags and SOCKET_EVENT_CLOSED) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_RX_SHUTDOWN) = 0 and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_CONNECTED) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_CONNECTED) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_TX_READY) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_TX_READY) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_TX_DONE) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_TX_DONE) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_TX_ACKED) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_TX_ACKED) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_TX_SHUTDOWN) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_TX_SHUTDOWN),

            Sock.State = TCP_STATE_CLOSE_WAIT =>
               (Sock.S_Event_Flags and SOCKET_EVENT_CLOSED) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_TX_SHUTDOWN) = 0 and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_CONNECTED) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_CONNECTED) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_RX_READY) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_RX_READY) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_RX_SHUTDOWN) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_RX_SHUTDOWN),

            Sock.State = TCP_STATE_LAST_ACK =>
               (Sock.S_Event_Flags and SOCKET_EVENT_CLOSED) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_TX_SHUTDOWN) = 0 and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_CONNECTED) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_CONNECTED) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_RX_READY) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_RX_READY) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_RX_SHUTDOWN) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_RX_SHUTDOWN),

            Sock.State = TCP_STATE_CLOSING =>
               (Sock.S_Event_Flags and SOCKET_EVENT_CLOSED) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_TX_SHUTDOWN) = 0 and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_CONNECTED) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_CONNECTED) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_RX_READY) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_RX_READY) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_RX_SHUTDOWN) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_RX_SHUTDOWN),

            Sock.State = TCP_STATE_TIME_WAIT =>
               (Sock.S_Event_Flags and SOCKET_EVENT_CONNECTED) = 0 and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_CLOSED) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_CLOSED) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_TX_READY) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_TX_READY) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_TX_DONE) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_TX_DONE) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_TX_ACKED) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_TX_ACKED) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_TX_SHUTDOWN) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_TX_SHUTDOWN) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_RX_READY) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_RX_READY) and then
               (if (Sock.S_Event_Mask and SOCKET_EVENT_RX_SHUTDOWN) /= 0 then
                  Sock.S_Event_Flags = SOCKET_EVENT_RX_SHUTDOWN),

            Sock.State = TCP_STATE_LISTEN =>
               (Sock.S_Event_Flags and SOCKET_EVENT_CONNECTED) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_CLOSED) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_TX_READY) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_TX_DONE) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_TX_ACKED) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_TX_SHUTDOWN) = 0 and then
               (Sock.S_Event_Flags and SOCKET_EVENT_RX_SHUTDOWN) = 0
         );

   procedure Tcp_Nagle_Algo
      (Sock  : in out Not_Null_Socket;
       Flags : in     unsigned;
       Error :    out Error_T)
      with
         Global => null,
         Post => Model(Sock) = Model(Sock)'Old;

   procedure Tcp_Update_Receive_Window
      (Sock : Not_Null_Socket)
      with
         Import => True,
         Convention => C,
         External_Name => "tcpUpdateReceiveWindow",
         Global => null,
         Post => Model (Sock) = Model(Sock)'Old;

private

   -- This function is only intended to compute and check the post-condition
   -- or the function TCP_Wait_For_Events by using the interleaving semantic
   -- If a change is made in the post condition of this procedure, the procedure
   -- TCP_Wait_For_Events must be updated accordingly
   procedure Tcp_Wait_For_Events_Proof
      (Sock       : in out Not_Null_Socket;
       Event_Mask : in     Socket_Event;
       Event      :    out Socket_Event)
      with
         Pre  =>
            Sock.S_Type = SOCKET_TYPE_STREAM and then
            -- Valid entries.
            (Event_Mask = SOCKET_EVENT_CONNECTED or else
            Event_Mask = SOCKET_EVENT_CLOSED or else
            Event_Mask = SOCKET_EVENT_TX_READY or else
            Event_Mask = SOCKET_EVENT_TX_DONE or else
            Event_Mask = SOCKET_EVENT_TX_ACKED or else
            Event_Mask = SOCKET_EVENT_TX_SHUTDOWN or else
            Event_Mask = SOCKET_EVENT_RX_READY or else
            Event_Mask = SOCKET_EVENT_RX_SHUTDOWN or else
            Event_Mask = (SOCKET_EVENT_CONNECTED or SOCKET_EVENT_CLOSED)),
         Post =>
            -- If Event is SOCKET_EVENT_CONNECTED
            (if (Event_Mask and SOCKET_EVENT_CONNECTED) /= 0 then
               (if Event = SOCKET_EVENT_CONNECTED then
                  (if Sock.State'Old = TCP_STATE_SYN_SENT then
                     Model(Sock) = (Model(Sock)'Old with delta
                           S_State => TCP_STATE_ESTABLISHED) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                           S_State => TCP_STATE_CLOSE_WAIT))))

            and then
            (if (Event_Mask and SOCKET_EVENT_CLOSED) /= 0 then
               (if Event = SOCKET_EVENT_CLOSED then
                  (if Sock.State'Old = TCP_STATE_SYN_SENT then
                     Model(Sock) = Model(Sock)'Old'Update
                        (S_State => TCP_STATE_CLOSED,
                         S_Reset_Flag => True))))

            and then
            (if (Event_Mask and SOCKET_EVENT_TX_READY) /=0 then
               (if Sock.State'Old = TCP_STATE_CLOSED then
                  Event = SOCKET_EVENT_TX_READY and then
                  Model(Sock) = Model(Sock)'Old) and then
               (if Event = SOCKET_EVENT_TX_READY then
                  (if Sock.State'Old = TCP_STATE_CLOSE_WAIT then
                     Model (Sock) = Model (Sock)'Old or else
                     -- If a RST has been received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_CLOSED then
                     Model (Sock) = Model (Sock)'Old
                  elsif Sock.State'Old in TCP_STATE_SYN_SENT
                                        | TCP_STATE_SYN_RECEIVED
                                        | TCP_STATE_ESTABLISHED
                  then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_ESTABLISHED) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSE_WAIT) or else
                     -- If a RST has been received
                     Model(Sock) = (Model (Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True))))

            and then
            (if (Event_Mask and SOCKET_EVENT_RX_READY) /= 0 then
               (if Event = SOCKET_EVENT_RX_READY then
                  (if Sock.State'Old in TCP_STATE_ESTABLISHED
                                       | TCP_STATE_SYN_RECEIVED
                                       | TCP_STATE_SYN_SENT
                  then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_ESTABLISHED) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSE_WAIT) or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_FIN_WAIT_1 then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_FIN_WAIT_1) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_FIN_WAIT_2) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSING) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     -- RST segment received or the connection has been
                     -- properly closed
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => False)
                  elsif Sock.State'Old = TCP_STATE_FIN_WAIT_2 then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_FIN_WAIT_2) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     -- RST segment received or the connection has been
                     -- properly closed
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => False)
                  elsif  Sock.State'Old in TCP_STATE_CLOSE_WAIT
                                         | TCP_STATE_CLOSING
                                         | TCP_STATE_TIME_WAIT
                                         | TCP_STATE_LAST_ACK
                  then
                     -- Nothing happen. The result is the same.
                     Model(Sock) = Model(Sock)'Old
                  elsif Sock.State'Old = TCP_STATE_CLOSED then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_Reset_Flag => Sock.reset_Flag'Old))))

            and then
            (if (Event_Mask and SOCKET_EVENT_TX_ACKED) /= 0 then
               (if Event = SOCKET_EVENT_TX_ACKED then
                  -- @TODO : To be continued if needed
                  (if Sock.State'Old = TCP_STATE_ESTABLISHED then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_ESTABLISHED) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSE_WAIT) or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_CLOSE_WAIT then
                     Model(Sock) = Model(Sock)'Old or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True))))

            and then
            (if (Event_Mask and SOCKET_EVENT_TX_DONE) /= 0 then
               (if Event = SOCKET_EVENT_TX_DONE then
                  (if Sock.State'Old in TCP_STATE_CLOSED
                                      | TCP_STATE_SYN_SENT
                                      | TCP_STATE_SYN_RECEIVED
                                      | TCP_STATE_FIN_WAIT_1
                                      | TCP_STATE_FIN_WAIT_2
                                      | TCP_STATE_TIME_WAIT
                  then
                     Model(Sock) = Model(Sock)'Old
                  elsif Sock.State'Old = TCP_STATE_CLOSING then
                     Model(Sock) = Model(Sock)'Old or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_LAST_ACK then
                     Model(Sock) = Model(Sock)'Old or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED)
                  elsif Sock.State'Old = TCP_STATE_CLOSE_WAIT then
                     Model(Sock) = Model(Sock)'Old or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_ESTABLISHED then
                     Model(Sock) = Model(Sock)'Old or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSE_WAIT) or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True))))

            and then
            (if (Event_Mask and SOCKET_EVENT_TX_SHUTDOWN) /= 0 then
               (if Event = SOCKET_EVENT_TX_SHUTDOWN then
                  (if Sock.State'Old = TCP_STATE_FIN_WAIT_1 then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_FIN_WAIT_2) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_CLOSING then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_CLOSE_WAIT then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_LAST_ACK then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED))))

            and then
            (if (Event_Mask and SOCKET_EVENT_RX_SHUTDOWN) /= 0 then
               (if Event = SOCKET_EVENT_RX_SHUTDOWN then
                  (if Sock.State'Old in TCP_STATE_SYN_RECEIVED
                                      | TCP_STATE_SYN_SENT
                                      | TCP_STATE_ESTABLISHED
                  then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_ESTABLISHED) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSE_WAIT) or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_LAST_ACK then
                     Model(Sock) = Model(Sock)'Old
                  elsif Sock.State'Old = TCP_STATE_FIN_WAIT_1 then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSING) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_FIN_WAIT_2 then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     -- RST segment received
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED,
                        S_Reset_Flag => True)
                  elsif Sock.State'Old = TCP_STATE_CLOSED then
                     Model(Sock) = Model(Sock)'Old)));

end Tcp_Misc_Binding;
