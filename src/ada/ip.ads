with Interfaces.C; use Interfaces.C;

package Ip is

   -----------------------
   -- IpAddr definition --
   -----------------------

   type fakeIP is array (1 .. 4) of unsigned_long;

   type IpAddr is record
      Length : unsigned_long;
      Ip     : fakeIP;
   end record
     with
      Convention => C;

   subtype IpAddrAny is IpAddr
     with
      Predicate => IpAddrAny.length = 4  or else
                   IpAddrAny.length = 16;

   IP_ADDR_ANY : aliased constant IpAddrAny
     with
      Import        => True,
      Convention    => C,
      External_Name => "IP_ADDR_ANY";

   IP_ADDR_UNSPECIFIED : aliased constant IpAddrAny
     with
      Import        => True,
      Convention    => C,
      External_Name => "IP_ADDR_UNSPECIFIED";

   -----------------------------
   -- Functions for contracts --
   -----------------------------

   function Is_Initialized_Ip (Ip : IpAddr) return Boolean is
      (Ip.length = 4 or else Ip.length = 16)
      with Ghost;

end Ip;
