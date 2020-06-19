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
   -- @TODO The transition to the close state are not taken into
   -- Account for now
   -- Zero or one transition.
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
            (if Sock.synQueue /= null then
               Is_Initialized_Ip (Sock.synQueue.Src_Addr) and then
               Sock.synQueue.Src_Port > 0 and then
               Is_Initialized_Ip (Sock.synQueue.Dest_Addr) and then
               Sock.synQueue.Next = null),

         -- C:tcpStateSynSent
         Sock.State = TCP_STATE_SYN_SENT =>
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_ESTABLISHED) or else
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_SYN_RECEIVED) or else
            -- Possibly unchanged
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_SYN_SENT),

         -- C:tcpStateSynReceived
         Sock.State = TCP_STATE_SYN_RECEIVED =>
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_ESTABLISHED) or else
            -- unchanged
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_SYN_RECEIVED),

         -- C:tcpStateEstablished
         Sock.State = TCP_STATE_ESTABLISHED =>
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_ESTABLISHED) or else
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSE_WAIT) or else
            -- unchanged
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_ESTABLISHED),

         -- C:tcpStateCloseWait
         Sock.State = TCP_STATE_CLOSE_WAIT =>
            -- Nothing happen. A call to close by the user is required
            -- to change of state here.
            Model(Sock) = Model(Sock)'Old,

         -- C:tcpStateLastAck
         Sock.State = TCP_STATE_LAST_ACK =>
            -- Model(Sock) = (Model(Sock)'Old with delta
            --    S_State => TCP_STATE_CLOSED) or else
            -- unchanged
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_LAST_ACK),

         -- C:tcpStateFinWait1
         Sock.State = TCP_STATE_FIN_WAIT_1 =>
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_FIN_WAIT_2) or else
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_TIME_WAIT) or else
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSING) or else
            -- unchanged
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_FIN_WAIT_1),

         -- C:tcpStateFinWait2
         Sock.State = TCP_STATE_FIN_WAIT_2 =>
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_TIME_WAIT) or else
            -- unchanged
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_FIN_WAIT_2),

         -- C:tcpStateClosing
         Sock.State = TCP_STATE_CLOSING =>
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_TIME_WAIT) or else
            -- unchanged
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_CLOSING),

         -- C:tcpStateTimeWait
         Sock.State = TCP_STATE_TIME_WAIT =>
            -- Nothing change. The 2MSL timer will close the connection
            Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_TIME_WAIT)
      );

end Tcp_Fsm_Binding;
