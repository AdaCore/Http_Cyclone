with System;

package body Socket_interface
with SPARK_Mode => Off
is

    procedure Get_Host_By_Name (
        Server_Name    : char_array; 
        Server_Ip_Addr : out IpAddr;
        Flags : Host_Resolver_Flags;
        Error : out Error_T)
    is
        F : Natural := 0;
    begin
        for I in Flags'Range loop
            F := F + Host_Resolver'Enum_Rep(Flags(I));
        end loop;
        Error := Error_T'Enum_Val(getHostByName(System.Null_Address, (Server_Name), Server_Ip_Addr, unsigned(F)));
    end Get_Host_By_Name;


    procedure Socket_Open (
        Sock:   out Socket_Struct;
        S_Type:     Socket_Type; 
        S_Protocol: Socket_Protocol)
    is 
    begin
        Sock := socketOpen(Socket_Type'Enum_Rep(S_Type), Socket_Protocol'Enum_Rep(S_Protocol));
    end Socket_Open;
    

    procedure Socket_Set_Timeout (
        Sock :    in out Socket_Struct;
        Timeout:  Systime)
    is
        Ret : unsigned;
    begin
        Ret := socketSetTimeout(Sock, Timeout);
    end Socket_Set_Timeout;

    procedure Socket_Set_Ttl (
        Sock : in out Socket_Struct;
        Ttl  :        Ttl_Type
    )
    is
        Ret : unsigned;
    begin
        Ret := socketSetTtl(Sock, unsigned_char(Ttl));
    end Socket_Set_Ttl;

    procedure Socket_Set_Multicast_Ttl (
        Sock : in out Socket_Struct;
        Ttl  :        Ttl_Type
    )
    is
        Ret : unsigned;
    begin
        Ret := socketSetMulticastTtl(Sock, unsigned_char(Ttl));
    end Socket_Set_Multicast_Ttl;

    procedure Socket_Connect (
        Sock: in out Socket_Struct;
        Remote_Ip_Addr : in IpAddr;
        Remote_Port : in Sock_Port;
        Error : out Error_T)
    is 
    begin
        Error := Error_T'Enum_Val(socketConnect (Sock, Remote_Ip_Addr, Remote_Port));
    end Socket_Connect;

    procedure Socket_Send (
        Sock: in Socket_Struct;
        Data: in char_array;
        Error : out Error_T)
    is
        Written : unsigned;
    begin
        Error := Error_T'Enum_Val(socketSend(Sock, Data, Data'Length, Written, 0));
    end Socket_Send;

    procedure Socket_Receive(
        Sock: Socket_Struct;
        Buf: out char_array;
        Error : out Error_T)
    is
        Received, Ret : unsigned;
    begin
        Ret := socketReceive(Sock, Buf, Buf'Length - 1, Received, 0);
        Error := Error_T'Enum_Val(Ret);
    end Socket_Receive;

    procedure Socket_Shutdown (
        Sock  :     Socket_Struct;
        How   :     Socket_Shutdown_Flags;
        Error : out Error_T)
    is
    begin
        Error := Error_T'Enum_Val(socketShutdown(Sock, Socket_Shutdown_Flags'Enum_Rep(How)));
    end Socket_Shutdown;

    procedure Socket_Close (Sock : in out Socket_Struct)
    is
    begin
        socketClose (Sock);
    end Socket_Close;

    procedure Socket_Set_Tx_Buffer_Size (
        Sock : in out Socket_Struct;
        Size :        Buffer_Size)
    is
        Ret : unsigned;
    begin
        Ret := socketSetTxBufferSize(Sock, unsigned_long(Size));
    end Socket_Set_Tx_Buffer_Size;

    procedure Socket_Set_Rx_Buffer_Size (
        Sock : in out Socket_Struct;
        Size :        Buffer_Size)
    is
        Ret : unsigned;
    begin
        Ret := socketSetRxBufferSize(Sock, unsigned_long(Size));
    end Socket_Set_Rx_Buffer_Size;

    procedure Socket_Bind (
        Sock          : in out Socket_Struct;
        Local_Ip_Addr :        IpAddr;
        Local_Port    :        Sock_Port) 
    is
        Ret : unsigned;
    begin
        Ret := socketBind(Sock, Local_Ip_Addr'Address, Local_Port);
    end Socket_Bind;

    procedure Socket_Listen (
        Sock   :     Socket_Struct;
        Backlog:     Natural;
        Error  : out Error_T)
    is
    begin
        Error := Error_T'Enum_Val(socketListen(Sock, unsigned(Backlog)));
    end Socket_Listen;

    procedure Socket_Accept (
        Sock           :     Socket_Struct;
        Client_Ip_Addr : out IpAddr;
        Client_Port    : out Sock_Port;
        Client_Socket  : out Socket_Struct)
    is
    begin
        Client_Socket := socketAccept(Sock, Client_Ip_Addr, Client_Port);
    end Socket_Accept;


end Socket_interface;
