package body Socket_Types
   with SPARK_Mode
is

   function Model (Sock : Not_Null_Socket)
      return Socket_Model
   is
      Sock_Model : Socket_Model;
   begin
      Sock_Model.S_Descriptor     := Sock.S_Descriptor    ;
      Sock_Model.S_Type           := Sock.S_Type          ;
      Sock_Model.S_Protocol       := Sock.S_Protocol      ;
      Sock_Model.S_localIpAddr    := Sock.S_localIpAddr   ;
      Sock_Model.S_Local_Port     := Sock.S_Local_Port    ;
      Sock_Model.S_remoteIpAddr   := Sock.S_remoteIpAddr  ;
      Sock_Model.S_Remote_Port    := Sock.S_Remote_Port   ;
      Sock_Model.S_Timeout        := Sock.S_Timeout       ;
      Sock_Model.S_TTL            := Sock.S_TTL           ;
      Sock_Model.S_Multicast_TTL  := Sock.S_Multicast_TTL ;
      Sock_Model.S_State          := Sock.State           ;
      Sock_Model.S_Rx_Buffer_Size := Sock.rxBufferSize    ;
      Sock_Model.S_Tx_Buffer_Size := Sock.txBufferSize    ;

      return Sock_Model;
   end Model;

end Socket_Types;