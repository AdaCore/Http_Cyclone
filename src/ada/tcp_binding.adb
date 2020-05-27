package body Tcp_Binding
   with SPARK_Mode => Off
is

   procedure Tcp_Receive
      (Sock     : in out Not_Null_Socket;
       Data     :    out char_array;
       Received :    out unsigned;
       Flags    :        unsigned;
       Error    :    out Error_T)
   is
      function tcpReceive
         (Sock     :     Not_Null_Socket;
          Data     : out char_array;
          Size     :     unsigned;
          Received : out unsigned;
          Flags    :     unsigned) return unsigned
      with
         Import        => True,
         Convention    => C,
         External_Name => "tcpReceive";
   begin
      Error := Error_T'Enum_Val
         (tcpReceive (Sock, Data, Data'Length, Received, Flags));
   end Tcp_Receive;

   procedure Tcp_Send
      (Sock    : in out Not_Null_Socket;
       Data    :        char_array;
       Written :    out Integer;
       Flags   :        unsigned;
       Error   :    out Error_T)
   is
      function tcpSend
         (Sock    :     Not_Null_Socket;
         Data    :     char_array;
         Length  :     unsigned;
         Written : out unsigned;
         Flags   :     unsigned) return unsigned
      with
         Import        => True,
         Convention    => C,
         External_Name => "tcpSend";
   begin
      Error := Error_T'Enum_Val
         (tcpSend (Sock, Data, Data'Length, unsigned (Written), Flags));
   end Tcp_Send;

end Tcp_Binding;