---------------------------------------------------
--                                               --
-- This file models useful C functions used to   --
-- process segements of data that are received   --
-- by the microcontroler                         --
--                                               --
---------------------------------------------------

pragma Unevaluated_Use_Of_Old (Allow);
pragma Ada_2020;

with Common_Type;    use Common_Type;
with Ip;             use Ip;
with Socket_Types;   use Socket_Types;
with Tcp_Type;       use Tcp_Type;

package Tcp_Fsm_Binding
   with SPARK_Mode
is

   -- This function is used to model the transitions that can happen
   -- when a segment is received from the network.
   -- This function model zero, one or more transitions that can happen when
   -- a message is received. (reprent →* = ∪_{n∈ℕ} →^n, n∈ℕ)
   -- @TODO The timer that close the connection after the TIME-WAIT state
   -- isn't considered in this function (2MLS timer). It should be added somewhere,
   -- either in this function or in another function
   procedure Tcp_Process_Segment(Sock : in out Not_Null_Socket)
   with
      Global => null,
      Depends => (Sock => Sock),
      Pre => Sock.S_Type = SOCKET_TYPE_STREAM,
      Post => Basic_Model(Sock) = Basic_Model(Sock)'Old,
      Contract_Cases => (
         Sock.State = TCP_STATE_CLOSED =>
            Model(Sock) = Model(Sock)'Old,

         -- C: tcpStateListen
         Sock.State = TCP_STATE_LISTEN =>
            Model(Sock) = Model(Sock)'Old and then
            Tcp_Syn_Queue_Item_Model(Sock.synQueue),
            -- (if Sock.synQueue /= null then
            --    Is_Initialized_Ip (Sock.synQueue.Src_Addr) and then
            --    Sock.synQueue.Src_Port > 0 and then
            --    Is_Initialized_Ip (Sock.synQueue.Dest_Addr)),

         -- C:tcpStateSynSent
         Sock.State = TCP_STATE_SYN_SENT =>
            -- Possibly unchanged if no message has been received
            Model(Sock) = Model(Sock)'Old or else
            -- Direct transitions
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_ESTABLISHED) or else
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_SYN_RECEIVED) or else
            -- Transitive closure
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSE_WAIT) or else
            -- A RST segment has been received
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED,
               S_Reset_Flag => True),

         -- C:tcpStateSynReceived
         Sock.State = TCP_STATE_SYN_RECEIVED =>
            -- Possibly unchanged if no message has been received
            Model(Sock) = Model(Sock)'Old or else
            -- Direct transition
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_ESTABLISHED) or else
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSE_WAIT) or else
            -- A RST segment has been received
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED,
               S_Reset_Flag => True),

         -- C:tcpStateEstablished
         Sock.State = TCP_STATE_ESTABLISHED =>
            -- Possibly unchanged if no message has been received
            Model(Sock) = Model(Sock)'Old or else
            -- Direct transition (if a FIN is received)
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSE_WAIT) or else
            -- A RST segment has been received
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED,
               S_Reset_Flag => True),

         -- C:tcpStateCloseWait
         Sock.State = TCP_STATE_CLOSE_WAIT =>
            -- Nothing happen. A call to close by the user is required
            -- to change of state here unless a RST hasn't been received.
            Model(Sock) = Model(Sock)'Old or else
            -- A RST segment has been received
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED,
               S_Reset_Flag => True),

         -- C:tcpStateLastAck
         Sock.State = TCP_STATE_LAST_ACK =>
            Model(Sock) = Model(Sock)'Old or else
            -- One transition
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED),

         -- C:tcpStateFinWait1
         Sock.State = TCP_STATE_FIN_WAIT_1 =>
            -- Possibly unchanged if no message has been received
            Model(Sock) = Model(Sock)'Old or else
            -- Direct transitions
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_FIN_WAIT_2) or else
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_TIME_WAIT) or else
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSING) or else
            -- A RST segment has been received
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED,
               S_Reset_Flag => True) or else
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED) or else
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED),

         -- C:tcpStateFinWait2
         Sock.State = TCP_STATE_FIN_WAIT_2 =>
            -- Possibly unchanged if no message has been received
            Model(Sock) = Model(Sock)'Old or else
            -- Direct transition
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_TIME_WAIT) or else
            -- A RST segment has been received
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED,
               S_Reset_Flag => True) or else
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED),

         -- C:tcpStateClosing
         Sock.State = TCP_STATE_CLOSING =>
            -- Possibly unchanged
            Model(Sock) = Model(Sock)'Old or else
            -- Direct transition
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_TIME_WAIT) or else
            -- A RST segment has been received
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED,
               S_Reset_Flag => True) or else
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED),

         -- C:tcpStateTimeWait
         Sock.State = TCP_STATE_TIME_WAIT =>
            -- Nothing change. The 2MSL timer will close the connection
            Model(Sock) = Model(Sock)'Old or else
            -- A RST segment has been received
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED)
            -- The case where a reset bit is received and the socket is
            -- closed and S_Type = SOCKET_TYPE_UNUSED can only happen
            -- once a Tcp_Abort has been called. For the purpose of the
            -- verification we consider that the Timer is directly called
            -- Then this case must be forgotten here without any impact
      );

   procedure Tcp_Process_One_Segment(Sock : in out Not_Null_Socket)
   with
      Global => null,
      Depends => (Sock => Sock),
      Pre => Sock.S_Type = SOCKET_TYPE_STREAM,
      Post => Basic_Model(Sock) = Basic_Model(Sock)'Old and then
              Sock.S_Event_Flags = Sock.S_Event_Flags'Old and then
              Sock.S_Event_Mask = Sock.S_Event_Mask'Old,
      Contract_Cases => (
         Sock.State = TCP_STATE_CLOSED =>
            Model(Sock) = Model(Sock)'Old,

         Sock.State = TCP_STATE_LISTEN =>
            Model(Sock) = Model(Sock)'Old and then
            Tcp_Syn_Queue_Item_Model(Sock.synQueue),
            -- (if Sock.synQueue /= null then
            --    Is_Initialized_Ip (Sock.synQueue.Src_Addr) and then
            --    Sock.synQueue.Src_Port > 0 and then
            --    Is_Initialized_Ip (Sock.synQueue.Dest_Addr)),

         Sock.State = TCP_STATE_SYN_SENT =>
            -- Possibly unchanged if no message has been received
            Model(Sock) = Model(Sock)'Old or else
            -- Direct transitions
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_ESTABLISHED) or else
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_SYN_RECEIVED) or else
            -- A RST segment has been received
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED,
               S_Reset_Flag => True),

         Sock.State = TCP_STATE_SYN_RECEIVED =>
            -- Possibly unchanged if no message has been received
            Model(Sock) = Model(Sock)'Old or else
            -- Direct transition
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_ESTABLISHED) or else
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSE_WAIT) or else
            -- A RST segment has been received
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED,
               S_Reset_Flag => True),

         Sock.State = TCP_STATE_ESTABLISHED =>
            -- Possibly unchanged if no message has been received
            Model(Sock) = Model(Sock)'Old or else
            -- Direct transition (if a FIN is received)
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSE_WAIT) or else
            -- A RST segment has been received
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED,
               S_Reset_Flag => True),

         Sock.State = TCP_STATE_CLOSE_WAIT =>
            -- Nothing happen. A call to close by the user is required
            -- to change of state here unless a RST hasn't been received.
            Model(Sock) = Model(Sock)'Old or else
            -- A RST segment has been received
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED,
               S_Reset_Flag => True),

         Sock.State = TCP_STATE_LAST_ACK =>
            Model(Sock) = Model(Sock)'Old or else
            -- A RST segment has been received
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED),

         Sock.State = TCP_STATE_FIN_WAIT_1 =>
            -- Possibly unchanged if no message has been received
            Model(Sock) = Model(Sock)'Old or else
            -- Direct transitions
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_FIN_WAIT_2) or else
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_TIME_WAIT) or else
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSING) or else
            -- A RST segment has been received
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED,
               S_Reset_Flag => True),

         Sock.State = TCP_STATE_FIN_WAIT_2 =>
            -- Possibly unchanged if no message has been received
            Model(Sock) = Model(Sock)'Old or else
            -- Direct transition
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_TIME_WAIT) or else
            -- A RST segment has been received
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED,
               S_Reset_Flag => True),

         Sock.State = TCP_STATE_CLOSING =>
            -- Possibly unchanged
            Model(Sock) = Model(Sock)'Old or else
            -- Direct transition
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_TIME_WAIT) or else
            -- A RST segment has been received
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED,
               S_Reset_Flag => True),

         Sock.State = TCP_STATE_TIME_WAIT =>
            -- Nothing change. The 2MSL timer will close the connection
            Model(Sock) = Model(Sock)'Old or else
            -- A RST segment has been received
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSED)
      );

end Tcp_Fsm_Binding;
