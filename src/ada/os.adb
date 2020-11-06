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

with System;

package body Os
   with SPARK_Mode => Off
is

   procedure Os_Acquire_Mutex (Mutex : Os_Mutex) is

      procedure osAcquireMutex (Mutex : System.Address)
        with
         Import        => True,
         Convention    => C,
         External_Name => "osAcquireMutex";

   begin
      osAcquireMutex (Mutex'Address);
   end Os_Acquire_Mutex;

   procedure Os_Release_Mutex (Mutex : Os_Mutex) is

      procedure osReleaseMutex (Mutex : System.Address)
        with
         Import        => True,
         Convention    => C,
         External_Name => "osReleaseMutex";

   begin
      osReleaseMutex (Mutex'Address);
   end Os_Release_Mutex;

   procedure Os_Reset_Event (Event : Os_Event) is
      procedure osResetEvent (Event : System.Address)
        with
         Import        => True,
         Convention    => C,
         External_Name => "osResetEvent";
   begin
      osResetEvent (Event'Address);
   end Os_Reset_Event;

   procedure Os_Set_Event (Event : Os_Event) is
      procedure osSetEvent (Event : System.Address)
        with
         Import        => True,
         Convention    => C,
         External_Name => "osSetEvent";
   begin
      osSetEvent (Event'Address);
   end Os_Set_Event;

   procedure Os_Set_Event (Event : access Os_Event) is
      procedure osSetEvent (Event : access Os_Event)
        with
         Import        => True,
         Convention    => C,
         External_Name => "osSetEvent";
   begin
      osSetEvent (Event);
   end Os_Set_Event;

   procedure Os_Wait_For_Event
      (Event   : Os_Event;
       Timeout : Systime)
   is
      procedure osWaitForEvent (Event : System.Address; Timeout : Systime)
        with
         Import        => True,
         Convention    => C,
         External_Name => "osWaitForEvent";
   begin
      osWaitForEvent (Event'Address, Timeout);
   end Os_Wait_For_Event;

   procedure Os_Wait_For_Event
      (Sock : in out Not_Null_Socket)
   is
      procedure osWaitForEvent (Event : System.Address; Timeout : Systime)
        with
         Import        => True,
         Convention    => C,
         External_Name => "osWaitForEvent";
   begin
      osWaitForEvent (Sock.S_Event'Address, Sock.S_Timeout);
   end Os_Wait_For_Event;

end Os;
