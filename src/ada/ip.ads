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
