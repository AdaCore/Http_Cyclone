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

package body Tcp_Timer_Interface is

   procedure Tcp_Tick (Sock : in out Not_Null_Socket) is
   begin
      null;
   end Tcp_Tick;

   procedure Tcp_Timer_Start
      (Timer       : in out Tcp_Timer;
       Timer_Delay : in     Systime)
   is
      function Os_Get_System_Time return Systime
      with
         Import => True,
         Convention => C,
         External_Name => "osGetSystemTime";
   begin
      -- Start Timer
      Timer.startTime := Os_Get_System_Time;
      Timer.interval := Timer_Delay;

      -- The timer is now running
      Timer.running := True;
   end Tcp_Timer_Start;

end Tcp_Timer_Interface;
