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
with Interfaces.C; use Interfaces.C;
with Ip;           use Ip;
with Socket_Types; use Socket_Types;

package Socket_Helper
   with SPARK_Mode
is

   procedure Get_Socket_From_Table
     (Index : in     Socket_Type_Index;
      Sock  :    out Socket)
     with
      Depends =>
         (Sock => Index),
      Post =>
         Sock /= null;

   procedure Get_Host_By_Name_H
     (Server_Name    :     char_array;
      Server_Ip_Addr : out IpAddr;
      Flags          :     unsigned;
      Error          : out Error_T)
     with
      Post =>
         (if Error = NO_ERROR then
            Is_Initialized_Ip (Server_Ip_Addr));

   procedure Free_Socket
      (Sock : in out Socket)
      with
         Post => Sock = null;

end Socket_Helper;
