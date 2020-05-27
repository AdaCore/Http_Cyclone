with Error_H;      use Error_H;
with Tcp_Type;     use Tcp_Type;

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

end Net_Mem_Interface;
