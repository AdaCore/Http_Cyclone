with System;

package Os_Types is

   type Os_Event is record
      handle : System.Address;
   end record
    with
      Convention => C;

   type Os_Event_Acc is access Os_Event;

   -- This record type is consistant with the OsMutex type for freertos
   type Os_Mutex is record
      Handle : System.Address;
   end record
     with
      Convention => C;

end Os_Types;
