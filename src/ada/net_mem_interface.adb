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

end Net_Mem_Interface;
