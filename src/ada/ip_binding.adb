with Interfaces.C; use Interfaces.C;
with System;       use System;

package body Ip_Binding is

   procedure Ip_Select_Source_Addr
      (Sock  :     Socket;
       Error : out Error_T)
   is
      function ipSelectSourceAddr
         (Net_Interface : Address;
          Dest_Addr : Address;
          Src_Addr  : Address)
      return unsigned
      with
         Import => True,
         Convention => C,
         External_Name => "ipSelectSourceAddr";
   begin
      Error := Error_T'Enum_Val(
         ipSelectSourceAddr(
            Sock.S_Net_Interface'Address,
            Sock.S_remoteIpAddr'Address,
            Sock.S_localIpAddr'Address));
   end Ip_Select_Source_Addr;

   function Ip_Is_Unspecified_Addr (Ip_Addr : IpAddr)
   return Boolean
   is
      function ipIsUnspecifiedAddr (Ip_Addr : Address)
      return int
      with
         Import => True,
         Convention => C,
         External_Name => "ipIsUnspecifiedAddr";
   begin
      if ipIsUnspecifiedAddr (Ip_Addr'Address) /= 0 then
         return True;
      else
         return False;
      end if;
   end Ip_Is_Unspecified_Addr;

end Ip_Binding;
