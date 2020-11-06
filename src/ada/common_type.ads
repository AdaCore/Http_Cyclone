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

pragma Ada_2020;

with Interfaces.C; use Interfaces.C;
with System;

package Common_Type is

   MAX_BYTES : constant := 128;

   -- type IpAddr is new System.Address;

   type Bool is new Boolean;
   for Bool'Size use int'Size;

   type Systime is new unsigned;

   type Sock_Descriptor is new unsigned;
   type Sock_Type is new unsigned;
   type Sock_Protocol is new unsigned;
   type Port is range 0 .. (2**16 - 1);
   type uint8 is mod 2**8;
   subtype Index is unsigned range 0 .. MAX_BYTES;
   type Block8 is array (Index range <>) of uint8;

   -- I limit the size of the Received buffer
   type Buffer_Index is range 0 .. 1024;
   type Received_Buffer is array (Buffer_Index range <>) of char
      with Relaxed_Initialization;

   type Send_Buffer is array (Buffer_Index range <>) of char;

end Common_Type;
