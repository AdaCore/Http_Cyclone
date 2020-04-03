with System;

package body Socket_interface is


    procedure Get_Host_By_Name (
        Server_Name    : char_array; 
        Server_Ip_Addr : out IpAddr)
    is
        Ret : unsigned;
        Null_pointer : System.Address;
    begin
        Ret := getHostByName(Null_pointer, (Server_Name), Server_Ip_Addr, 0);
    end;


    procedure Socket_Open (
        Sock: in out Socket_Struct;
        S_Type:     Socket_Type; 
        S_Protocol: Socket_Protocol)
    is 
    begin
        Sock := socketOpen(1, 6);
    end Socket_Open;
    

    procedure Socket_Set_Timeout (
        sock : Socket_Struct;
        timeout : Systime)
    is 
        Ret : unsigned;
    begin
        Ret := socketSetTimeout(Sock, timeout);
    end Socket_Set_Timeout;

    procedure Socket_Connect (
        Sock:            Socket_Struct;
        Remote_Ip_Addr : IpAddr;
        Remote_Port   :  Sock_Port)
    is 
        Ret : unsigned;
    begin
        Ret := socketConnect (Sock, Remote_Ip_Addr, Remote_Port);
    end Socket_Connect;

    procedure Socket_Send (
        Sock: Socket_Struct;
        Data: char_array)
    is
        Ret, Written : unsigned;
    begin
        Ret := socketSend(Sock, Data, Data'Length, Written, 0);
    end Socket_Send;

    function Socket_Receive(
        Sock: Socket_Struct;
        Buf: out char_array)
    return Integer
    is
        Ret, Received : unsigned;
    begin
        return Integer(socketReceive(Sock, Buf, Buf'Length - 1, Received, 0));
    end Socket_Receive;

    procedure Socket_Shutdown (
        Sock: Socket_Struct)
    is
        Ret : unsigned;
    begin
        Ret := socketShutdown(Sock, 2);
    end Socket_Shutdown;

    procedure Socket_Close (Sock : Socket_Struct)
    is
    begin
        socketClose (Sock);
    end Socket_Close;


end Socket_interface;