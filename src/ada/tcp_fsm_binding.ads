---------------------------------------------------
--                                               --
-- This file models useful C functions used to   --
-- process segements of data that are received   --
-- by the microcontroler                         --
--                                               --
---------------------------------------------------


pragma Unevaluated_Use_Of_Old (Allow);

with Common_Type;    use Common_Type;
with Ip;             use Ip;
with Socket_Types;   use Socket_Types;
with Tcp_Type;       use Tcp_Type;

package Tcp_Fsm_Binding
   with SPARK_Mode
is

   -- This function is used to model the transitions that can happen
   -- when a segment is received from the network.
   procedure Tcp_Process_Segment(Sock : in out Not_Null_Socket)
   with
      Global => null,
      Depends => (Sock => Sock),
      Pre => Sock.S_Type = SOCKET_TYPE_STREAM,
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
         others => Model(Sock) = Model(Sock)'Old
      );

end Tcp_Fsm_Binding;
