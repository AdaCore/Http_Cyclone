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
with Tcp_Type;     use Tcp_Type;
with Socket_Types; use Socket_Types;
with System;

package Net_Mem_Interface
   with SPARK_Mode
is

   procedure Net_Rx_Buffer_Set_Length
      (Buffer : in out Tcp_Rx_Buffer;
       Length :        Rx_Buffer_Size;
       Error  :    out Error_T)
   with
      Depends =>
         (Buffer =>+ Length,
          Error  =>  (Buffer, Length));

   procedure Net_Tx_Buffer_Set_Length
      (Buffer : in out Tcp_Tx_Buffer;
       Length :        Tx_Buffer_Size;
       Error  :    out Error_T)
   with
      Depends =>
         (Buffer =>+ Length,
          Error  =>  (Buffer, Length));

   procedure memPoolFree (Pointer : System.Address)
   with
      Import => True,
      Convention => C,
      External_Name => "memPoolFree",
      Global => null;

   procedure Mem_Pool_Free
      (Queue_Item : in out Tcp_Syn_Queue_Item_Acc)
      with
         Depends => (Queue_item => null,
                     null => Queue_Item),
         Global => null,
         Post => Queue_Item = null;
   
   procedure Net_Buffer_Free
      (Queue_Item : in out Socket_Queue_Item_Acc)
   with
      Depends => (Queue_Item => null,
                  null => Queue_Item),
      Global => null,
      Post => Queue_Item = null;

end Net_Mem_Interface;
