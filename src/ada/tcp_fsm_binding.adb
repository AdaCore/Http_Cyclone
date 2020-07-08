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