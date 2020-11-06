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
with System;       use System;

package body Net_Mem_Interface
   with SPARK_Mode => Off
is

   function netBufferSetLength
      (Buffer : Address;
       Length : unsigned_long) return unsigned
   with
      Import => True,
      Convention => C,
      External_Name => "netBufferSetLength";

   procedure Net_Tx_Buffer_Set_Length
      (Buffer : in out Tcp_Tx_Buffer;
       Length :        Tx_Buffer_Size;
       Error  :    out Error_T)
   is
   begin
      Error := Error_T'Enum_Val(netBufferSetLength (Buffer'Address, unsigned_long(Length)));
   end Net_Tx_Buffer_Set_Length;

   procedure Net_Rx_Buffer_Set_Length
      (Buffer : in out Tcp_Rx_Buffer;
       Length :        Rx_Buffer_Size;
       Error  :    out Error_T)
   is
   begin
      Error := Error_T'Enum_Val(netBufferSetLength (Buffer'Address, unsigned_long(Length)));
   end Net_Rx_Buffer_Set_Length;

   procedure Mem_Pool_Free
      (Queue_Item : in out Tcp_Syn_Queue_Item_Acc)
   is
      procedure memPoolFree
         (Queue_Item : Tcp_Syn_Queue_Item_Acc)
      with
         Import => True,
         Convention => C,
         External_Name => "memPoolFree";
   begin
      memPoolFree (Queue_Item);
   end Mem_Pool_Free;

   procedure Net_Buffer_Free
      (Queue_Item : in out Socket_Queue_Item_Acc)
   is
      procedure netBufferFree
         (Buffer : System.Address)
      with
         Import => True,
         Convention => C,
         External_Name => "netBufferFree";
   begin
      netBufferFree (Queue_Item.Buffer);
   end Net_Buffer_Free;

end Net_Mem_Interface;
