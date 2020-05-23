----------------------------------------------------
--                                                --
-- This file only contains some proofs to be used --
-- in tcp.adb. The proof models transitions       --
-- between states that can happen when the timer  --
-- ellapsed.                                      --
--                                                --
----------------------------------------------------

with Socket_Types; use Socket_Types;
with Tcp_Type;     use Tcp_Type;

package Tcp_Timer_Interface
   with SPARK_Mode
is

   procedure Tcp_Tick (Sock : in out Not_Null_Socket)
   with
      Depends => (Sock =>+ null),
      Pre =>
         Sock.S_Type = SOCKET_TYPE_STREAM and then
         Sock.State /= TCP_STATE_CLOSED,
      Contract_Cases => (
         Sock.State = TCP_STATE_TIME_WAIT =>
            (Sock.S_Type = SOCKET_TYPE_UNUSED and then
             Sock.State  = TCP_STATE_CLOSED),
         others => True
      );

end Tcp_Timer_Interface;


