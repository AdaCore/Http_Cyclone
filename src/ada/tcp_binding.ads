with Error_H     ; use Error_H;
with Interfaces.C; use Interfaces.C;
with Socket_Types; use Socket_Types;

package Tcp_Binding
   with SPARK_Mode => On
is

   procedure Tcp_Receive
      (Sock     : in out Not_Null_Socket;
       Data     :    out char_array;
       Received :    out unsigned;
       Flags    :        unsigned;
       Error    :    out Error_T);

   procedure Tcp_Send
      (Sock    : in out Not_Null_Socket;
       Data    :        char_array;
       Written :    out Integer;
       Flags   :        unsigned;
       Error   :    out Error_T);

end Tcp_Binding;