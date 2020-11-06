------------------------------------------------------------------------------
--                              HTTP_Cyclone                                --
--                                                                          --
--                        Copyright (C) 2020, AdaCore                       --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General  Public  License  distributed  with  this  software;   see  file --
-- LICENSE  If not, go to http://www.gnu.org/licenses for a complete copy   --
-- of the license.                                                          --
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- This file only contains some proofs to be used                           --
-- in tcp.adb. The proof models transitions                                 --
-- between states that can happen when the timer                            --
-- ellapsed.                                                                --
------------------------------------------------------------------------------


with Common_Type;  use Common_Type;
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
            (if Sock.owned_Flag'Old = False then
               Sock.S_Type = SOCKET_TYPE_UNUSED and then
               Sock.State  = TCP_STATE_CLOSED),
         others => True
      );

   procedure Tcp_Timer_Start
      (Timer       : in out Tcp_Timer;
       Timer_Delay : in     Systime);

end Tcp_Timer_Interface;
