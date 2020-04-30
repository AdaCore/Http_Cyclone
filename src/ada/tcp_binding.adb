with System;

package body Tcp_Binding 
    with SPARK_Mode => Off
is


    procedure Tcp_Get_Dynamic_Port (
               P: out Port
    )
    is
        function netGetRand return unsigned
        with
            Import => True,
            Convention => C,
            External_Name => "netGetRand";

    begin
        -- Retrieve current port number
        P := Tcp_Dynamic_Port;
        -- Invalid port number?
        if P < SOCKET_EPHEMERAL_PORT_MIN or P > SOCKET_EPHEMERAL_PORT_MAX then
            P := SOCKET_EPHEMERAL_PORT_MIN + Port(netGetRand mod unsigned(SOCKET_EPHEMERAL_PORT_MAX - SOCKET_EPHEMERAL_PORT_MIN + 1));
        end if;

        if P < SOCKET_EPHEMERAL_PORT_MAX then
            Tcp_Dynamic_Port := P + 1;
        else
            Tcp_Dynamic_Port := SOCKET_EPHEMERAL_PORT_MIN;
        end if;
    end Tcp_Get_Dynamic_Port;

    procedure Tcp_Connect (
            Sock : in out Socket;
            Remote_Ip_Addr : IpAddr;
            Remote_Port : Port;
            Error : out Error_T)
    is 
        function tcpConnect (Sock : Socket; remoteIpAddr : System.Address; remotePort : Port)
        return unsigned
        with
            Import => True,
            Convention => C,
            External_Name => "tcpConnect";
    begin
        Error := Error_T'Enum_Val(tcpConnect (Sock, Remote_Ip_Addr'Address, Remote_Port));
    end Tcp_Connect;

    procedure Tcp_Listen (
            Sock : Socket;
            Backlog : unsigned;
            Error : out Error_T)
    is
        function tcpListen (Sock : Socket; backlog : unsigned)
        return unsigned
        with
            Import => True,
            Convention => C,
            External_Name => "tcpListen";
    begin
        Error := Error_T'Enum_Val(tcpListen (Sock, Backlog));
    end Tcp_Listen;

    procedure Tcp_Accept (
            Sock : Socket;
            Client_Ip_Addr : out IpAddr;
            Client_Port : out Port;
            Client_Socket : out Socket)
    is
        function tcpAccept (Sock : Socket; Client_Ip_Addr : out IpAddr; P : out Port)
        return Socket
        with
            Import => True,
            Convention => C,
            External_Name => "tcpAccept";
    begin
        Client_Socket := tcpAccept (Sock, Client_Ip_Addr, Client_Port);
    end Tcp_Accept;

    procedure Tcp_Send (
            Sock : in out Socket;
            Data : char_array;
            Written : out Integer;
            Flags : unsigned;
            Error : out Error_T)
    is
        function tcpSend (Sock : Socket ; Data : char_array ; Length : unsigned; Written : out unsigned ; Flags : unsigned)
        return unsigned
        with
            Import => True,
            Convention => C,
            External_Name => "tcpSend";
    begin
        Error := Error_T'Enum_Val(tcpsend(Sock, Data, Data'Length, unsigned(Written), Flags));
    end Tcp_Send;

    procedure Tcp_Receive (
            Sock : in out Socket;
            Data : out char_array;
            Received : out unsigned;
            Flags : unsigned;
            Error : out Error_T)
    is
        function tcpReceive (Sock : socket; Data : out char_array; Size : unsigned; Received : out unsigned ; Flags : unsigned)
        return unsigned
        with
            Import => True,
            Convention => C,
            External_Name => "tcpReceive";
    begin
        Error := Error_T'Enum_Val(tcpReceive(Sock, Data, Data'Length, Received, Flags));
    end Tcp_Receive;

    procedure Tcp_Kill_Oldest_Connection (
        Sock : out Socket
    )
    is
        function tcpKillOldestConnection
        return Socket
        with
            Import => True,
            Convention => C,
            External_Name => "tcpKillOldestConnection";
    
    -- Time : Systime := Os_Get_System_Time;
    -- Oldest_Sock : Socket := null;
    begin
        Sock := tcpKillOldestConnection;
        -- for I in Socket_Table'Range loop
        --     Get_Socket_From_Table(I, Sock);
            
        --     if Sock.S_Type = Socket_Type'Enum_Rep(SOCKET_TYPE_STREAM) then
        --         if Sock
        --     end if;
        -- end loop;
    end Tcp_Kill_Oldest_Connection;

    procedure Tcp_Shutdown (
        Sock : in out Socket;
        How : unsigned;
        Error : out Error_T)
    is
        function tcpShutdown (Sock : Socket ; how : unsigned)
        return unsigned
        with
            Import => True,
            Convention => C,
            External_Name => "tcpShutdown";
    begin
        Error := Error_T'Enum_Val(tcpShutdown(Sock, How));
    end Tcp_Shutdown;

end Tcp_Binding;