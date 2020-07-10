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
