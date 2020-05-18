with Os_Types; use Os_Types;

package Net is

   Net_Mutex : aliased constant Os_Mutex
     with
      Import        => True,
      Convention    => C,
      External_Name => "netMutex";

end Net;
