with Socket; use Socket; 

package Ada_Main is
   
    function Ada_Connect_Socket (S_Type: Sock_Type; protocol: Sock_Protocol)
    return Socket
      with
        Export => True,
        Convention => C,
        External_Name => "ada_connect_socket"
    is
    begin
        return socketOpen(S_Type, protocol);
    end Ada_Connect_Socket;

end Ada_Main;