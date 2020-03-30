with Interfaces.C; use Interfaces.C;

package Ip is
   
   type fakeIP is array (1 .. 4) of unsigned_long;

   type IpAddr is 
      record
         length: unsigned_long;
         Ip: fakeIP;
      end record
     with Convention => C;


end Name;