with Ada_Socket; use Ada_Socket; 

package Ada_Main is
   
    function Ada_Open_Socket (S_Type: Sock_Type; protocol: Sock_Protocol)
    return Socket
      with
        Export => True,
        Convention => C,
        External_Name => "ada_open_socket";

end Ada_Main;
