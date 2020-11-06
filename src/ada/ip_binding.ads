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

with Error_H;      use Error_H;
with Ip;           use Ip;
with System;       use System;

package Ip_Binding
   with SPARK_Mode
is

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
     with Global => null,
          Post => (if Ip_Is_Unspecified_Addr'Result = False then
                     Is_Initialized_Ip (Ip_Addr));

end Ip_Binding;
