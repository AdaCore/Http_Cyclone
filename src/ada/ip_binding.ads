with Error_H;      use Error_H;
with Ip;           use Ip;
with Socket_Types; use Socket_Types;

package Ip_Binding is

   procedure Ip_Select_Source_Addr
      (Sock  : Socket;
       Error : out Error_T)
      with Global => null;

   function Ip_Is_Unspecified_Addr (Ip_Addr : IpAddr)
   return Boolean
     with Global => null;

end Ip_Binding;