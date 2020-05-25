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