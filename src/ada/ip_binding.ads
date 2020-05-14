with Error_H;      use Error_H;
with Ip;           use Ip;
with System;       use System;

package Ip_Binding is

   procedure Ip_Select_Source_Addr
      (Net_Interface  : in out System.Address;
       Dest_Addr      : in     IpAddr;
       Src_Addr       :    out IpAddr;
       Error          :    out Error_T)
      with 
         Global => null,
         Pre => Is_Initialized_Ip (Dest_Addr),
         Post =>
            (if Error = NO_ERROR then
               Is_Initialized_Ip (Src_Addr));

   function Ip_Is_Unspecified_Addr (Ip_Addr : IpAddr)
   return Boolean
     with Global => null;

end Ip_Binding;