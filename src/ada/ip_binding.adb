------------------------------------------------------------------------------
--                              HTTP_Cyclone                                --
--                                                                          --
--                        Copyright (C) 2020, AdaCore                       --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General  Public  License  distributed  with  this  software;   see  file --
-- LICENSE  If not, go to http://www.gnu.org/licenses for a complete copy   --
-- of the license.                                                          --
------------------------------------------------------------------------------

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
      Error := Error_T'Enum_Val (
         ipSelectSourceAddr (
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
