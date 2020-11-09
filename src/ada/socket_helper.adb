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

with System;

package body Socket_Helper with
   SPARK_Mode => Off
is

   procedure Get_Socket_From_Table
     (Index : in     Socket_Type_Index;
      Sock  :    out Socket)
   is

      function getSocketFromTable
        (index : unsigned)
      return Socket
        with
         Import        => True,
         Convention    => C,
         External_Name => "getSocketFromTable";

   begin
      Sock := getSocketFromTable (unsigned (Index));
   end Get_Socket_From_Table;

   --  Temporaire, à supprimer.
   --  Juste pour faire tourner gnatprove pour le moment
   procedure Get_Host_By_Name_H
     (Server_Name    :     char_array;
      Server_Ip_Addr : out IpAddr;
      Flags          :     unsigned;
      Error          : out Error_T)
   is

      function getHostByName
        (Net_Interface   :     System.Address;
         Server_Name     :     char_array;
         Serveur_Ip_Addr : out IpAddr;
         Flags           :     unsigned)
      return unsigned
        with
         Import        => True,
         Convention    => C,
         External_Name => "getHostByName";

   begin
      Error :=
        Error_T'Enum_Val
          (getHostByName
             (System.Null_Address, Server_Name, Server_Ip_Addr, Flags));
   end Get_Host_By_Name_H;

   procedure Free_Socket
      (Sock : in out Socket)
   is
      pragma Annotate (CodePeer, Skip_Analysis);
   begin
      Sock := null;
   end Free_Socket;

end Socket_Helper;
