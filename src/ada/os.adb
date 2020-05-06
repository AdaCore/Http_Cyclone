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

end Os;
