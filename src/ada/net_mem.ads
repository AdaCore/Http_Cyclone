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
with System;

package Net_Mem is

   --  Size of the buffers
#if NET_MEM_POOL_BUFFER_SIZE'Defined then
   NET_MEM_POOL_BUFFER_SIZE : constant Positive := $NET_MEM_POOL_BUFFER_SIZE;
#else
   NET_MEM_POOL_BUFFER_SIZE : constant Positive := 1536;
#end if;

   type Chunk_Desc is record
      address : System.Address;
      length  : unsigned_short;
      size    : unsigned_short;
   end record
     with
      Convention => C, Object_Size => 32 + System.Word_Size;
end Net_Mem;
