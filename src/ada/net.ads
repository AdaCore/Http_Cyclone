with Os; use Os;

package Net is

   Net_Mutex : aliased constant Os_Mutex
     with
      Import        => True,
      Convention    => C,
      External_Name => "netMutex";

end Net;
