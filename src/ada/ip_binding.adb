with Interfaces.C; use Interfaces.C;

package body Ip_Binding is

   procedure Ip_Select_Source_Addr
      (Net_Interface  : in out System.Address;
       Dest_Addr      : in     IpAddr;
       Src_Addr       :    out IpAddr;
       Error          :    out Error_T)
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
            Net_Interface => Net_Interface'Address,
            Dest_Addr     => Dest_Addr'Address,
            Src_Addr      => Src_Addr'Address));
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
