with Interfaces.C; use Interfaces.C;

package Ip is

   type fakeIP is array (1 .. 4) of unsigned_long;

   type IpAddr is record
      length : unsigned_long;
      Ip     : fakeIP;
   end record
     with
      Convention => C;

   subtype IpAddrAny is IpAddr 
     with
      Predicate => IpAddrAny.length > 0;

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

end Ip;
