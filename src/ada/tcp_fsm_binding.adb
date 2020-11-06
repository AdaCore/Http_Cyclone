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

package body Tcp_Fsm_Binding
with SPARK_Mode => On
is

   procedure Tcp_Process_Segment(Sock : in out Not_Null_Socket)
   is begin
      for J in 1 .. 3 loop
         Tcp_Process_One_Segment (Sock);
      end loop;
   end Tcp_Process_Segment;

   procedure Tcp_Process_One_Segment(Sock : in out Not_Null_Socket)
   with SPARK_Mode => Off
   is
   begin
      null;
   end Tcp_Process_One_Segment;

end Tcp_Fsm_Binding;
