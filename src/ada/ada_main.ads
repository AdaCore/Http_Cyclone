package Ada_Main is
   
    procedure HTTP_Client_Test
      with
        Export => True,
        Convention => C,
        External_Name => "http_client_test";

end Ada_Main;
