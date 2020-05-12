with System;
with Common_Type; use Common_Type;

package Os with
   SPARK_Mode
is

   type Os_Event is record
      handle : System.Address;
   end record
    with
      Convention => C;

   -- This record type is consistant with the OsMutex type for freertos
   type Os_Mutex is record
      Handle : System.Address;
   end record
     with
      Convention => C;

   -- Mutex management
   procedure Os_Acquire_Mutex (Mutex : Os_Mutex);

   procedure Os_Release_Mutex (Mutex : Os_Mutex);

   function Os_Get_System_Time return Systime
     with
      Import        => True,
      Convention    => C,
      External_Name => "osGetSystemTime",
      Global        => null;
   
   procedure Os_Reset_Event (Event : Os_Event);

   procedure Os_Wait_For_Event
      (Event   : Os_Event;
       Timeout : Systime);

end Os;
