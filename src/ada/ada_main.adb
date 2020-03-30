with Ada_Socket; use Ada_Socket; 

package body Ada_Main is
      
    function Ada_Open_Socket (S_Type: Sock_Type; protocol: Sock_Protocol)
    return Socket
    is
    begin
        return socketOpen(S_Type, protocol);
    end Ada_Open_Socket;

end Ada_Main;
