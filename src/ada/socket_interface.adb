with System;
with Error_H; use Error_H;

package body Socket_interface 
with SPARK_Mode
is

    procedure Get_Host_By_Name (
        Server_Name    : char_array; 
        Server_Ip_Addr : out IpAddr)
    is
        Null_pointer : System.Address;
    begin
        if getHostByName(Null_pointer, (Server_Name), Server_Ip_Addr, 0) /= 0 then
            raise Socket_error;
        end if;
    end;


    procedure Socket_Open (
        Sock: in out Socket_Struct;
        S_Type:     Socket_Type; 
        S_Protocol: Socket_Protocol)
    is 
    begin
        Sock := socketOpen(Socket_Type'Enum_Rep(S_Type), Socket_Protocol'Enum_Rep(S_Protocol));
    end Socket_Open;
    

    procedure Socket_Set_Timeout (
        sock : Socket_Struct;
        timeout : Systime)
    is 
    begin
        if socketSetTimeout(Sock, timeout) /= 0 then
            raise Socket_error;
        end if;
    end Socket_Set_Timeout;

    procedure Socket_Connect (
        Sock:            Socket_Struct;
        Remote_Ip_Addr : IpAddr;
        Remote_Port   :  Sock_Port)
    is 
    begin
        if socketConnect (Sock, Remote_Ip_Addr, Remote_Port) /= 0 then
            raise Socket_error;
        end if;
    end Socket_Connect;

    procedure Socket_Send (
        Sock: Socket_Struct;
        Data: char_array)
    is
        Written : unsigned;
    begin
        if socketSend(Sock, Data, Data'Length, Written, 0) /= 0 then
            raise Socket_error;
        end if;
    end Socket_Send;

    procedure Socket_Receive(
        Sock: Socket_Struct;
        Buf: out char_array;
        End_Received : out Boolean)
    is
        Received, Ret : unsigned;
    begin
        Ret := socketReceive(Sock, Buf, Buf'Length - 1, Received, 0);
        End_Received := Ret = ERROR_END_OF_STREAM;
        if Ret /= 0 and then Ret /= ERROR_END_OF_STREAM then
            raise Socket_error;
        end if;
    end Socket_Receive;

    procedure Socket_Shutdown (
        Sock: Socket_Struct)
    is
    begin
        if socketShutdown(Sock, 2) /= 0 then
            raise Socket_error;
        end if;
    end Socket_Shutdown;

    procedure Socket_Close (Sock : Socket_Struct)
    is
    begin
        socketClose (Sock);
    end Socket_Close;


end Socket_interface;
