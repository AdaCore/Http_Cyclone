with System;
with Os; use Os;
with Net; use Net;
with Tcp_Binding, Udp_Binding; use Tcp_binding, Udp_Binding;
with Tcp_Type; use Tcp_Type;

package body Socket_interface
with SPARK_Mode => On
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
        Sock:   out Socket;
        S_Type:     Socket_Type; 
        S_Protocol: Socket_Protocol)
    is
        Error : Error_T;
        P : Port;
        Protocol : Socket_Protocol;
    begin
        -- Initialize socket handle
        Sock := null;
        Os_Acquire_Mutex (Net_Mutex);

        case S_Type is
            when SOCKET_TYPE_STREAM =>
                -- Always use TCP as underlying transport protocol
                Protocol := SOCKET_IP_PROTO_TCP;
                -- Get an ephemeral port number
                P := Tcp_Get_Dynamic_Port;
                Error := NO_ERROR;
            when SOCKET_TYPE_DGRAM =>
                --Always use UDP as underlying transport protocol
                Protocol := SOCKET_IP_PROTO_UDP;
                -- Get an ephemeral port number
                P := Udp_Get_Dynamic_Port;
                Error := NO_ERROR;
            when SOCKET_TYPE_RAW_IP | SOCKET_TYPE_RAW_ETH =>
                P := 0;
                Error := NO_ERROR;
            when others =>
                Error := ERROR_INVALID_PARAMETER;
        end case;

        if Error = NO_ERROR then
            for I in Socket_Table'Range loop
                if socket_Table(I).S_Type = Socket_Type'Enum_Rep(SOCKET_TYPE_UNUSED) then
                    --@TODO change this
                    Sock.all := Socket_Table(I);
                end if;
                exit when socket_Table(I).S_Type = Socket_Type'Enum_Rep(SOCKET_TYPE_UNUSED);
            end loop;

            if Sock = null then
                Sock := Tcp_Kill_Oldest_Connection;
            end if;

            if Sock /= null then
                -- Reset Socket
                Sock.S_Type := Socket_Type'Enum_Rep(S_Type);
                Sock.S_Protocol := Socket_Protocol'Enum_Rep(S_Protocol);
                Sock.S_Local_Port := P;
                Sock.S_Timeout := Systime'Last;
                Sock.S_remoteIpAddr.length := 0;
                Sock.S_localIpAddr.length := 0;
                Sock.S_Remote_Port := 0;
                Sock.S_Net_Interface := System.Null_Address;
                Sock.S_TTL := 0;
                Sock.S_Multicast_TTL := 0;
                Sock.S_errnoCode := 0;
                Sock.S_Event_Mask := 0;
                Sock.S_Event_Flags := 0;
                Sock.userEvent := System.Null_Address;
                Sock.State := TCP_STATE_CLOSED;
                Sock.owned_Flag := 0;
                Sock.closed_Flag := 0;
                Sock.reset_Flag := 0;
                Sock.smss := 0;
                Sock.rmss := 0;
                Sock.iss := 0;
                Sock.irs := 0;
                Sock.sndUna := 0;
                Sock.sndNxt := 0;
                Sock.sndUser := 0;
                Sock.sndWnd := 0;
                Sock.maxSndWnd := 0;
                Sock.sndWl1 := 0;
                Sock.sndWl2 := 0;
                Sock.rcvNxt := 0; 
                Sock.rcvUser := 0;  
                Sock.rcvWnd := 0;   
                Sock.rttBusy := 0;
                Sock.rttSeqNum := 0;
                Sock.rettStartTime := 0;
                Sock.srtt := 0;
                Sock.rttvar := 0;
                Sock.rto := 0;
                Sock.congestState := TCP_CONGEST_STATE_IDLE;
                Sock.cwnd := 0;
                Sock.ssthresh := 0;
                Sock.dupAckCount := 0;
                Sock.n := 0;
                Sock.recover := 0;
                Sock.txBuffer.chunkCount := 0;
                Sock.txBufferSize := 2860;
                Sock.rxBuffer.chunkCount := 0;
                Sock.rxBufferSize := 2860;
                Sock.retransmitQueue := System.Null_Address;
                Sock.retransmitCount := 0;
                Sock.synQueue := System.Null_Address;
                Sock.synQueueSize := 0;
                Sock.wndProbeCount := 0;
                Sock.wndProbeInterval := 0;
                Sock.sackPermitted := 0;
                Sock.sackBlockCount := 0;
                Sock.receiveQueue := System.Null_Address;
            end if;
        end if;

        Os_Release_Mutex (Net_Mutex);

        -- socketOpen(Socket_Type'Enum_Rep(S_Type), Socket_Protocol'Enum_Rep(S_Protocol));
    end Socket_Open;
    

    procedure Socket_Set_Timeout (
        Sock :    in out Socket;
        Timeout:  Systime)
    is
    begin
        Os_Acquire_Mutex (Net_Mutex);
        Sock.S_Timeout := Timeout;
        Os_Release_Mutex (Net_Mutex);
    end Socket_Set_Timeout;

    procedure Socket_Set_Ttl (
        Sock : in out Socket;
        Ttl  :        Ttl_Type
    )
    is
    begin
        Os_Acquire_Mutex (Net_Mutex);
        Sock.S_TTL := unsigned_char(Ttl);
        Os_Release_Mutex (Net_Mutex);
    end Socket_Set_Ttl;

    procedure Socket_Set_Multicast_Ttl (
        Sock : in out Socket;
        Ttl  :        Ttl_Type
    )
    is
    begin
        Os_Acquire_Mutex (Net_Mutex);
        Sock.S_Multicast_TTL := unsigned_char(Ttl);
        Os_Release_Mutex (Net_Mutex);
    end Socket_Set_Multicast_Ttl;

    procedure Socket_Connect (
        Sock: in out Socket;
        Remote_Ip_Addr : in IpAddr;
        Remote_Port : in Port;
        Error : out Error_T)
    is 
    begin
        Error := Error_T'Enum_Val(socketConnect (Sock, Remote_Ip_Addr, Remote_Port));
    end Socket_Connect;

    procedure Socket_Send (
        Sock: in Socket;
        Data: in char_array;
        Error : out Error_T)
    is
        Written : unsigned;
    begin
        Error := Error_T'Enum_Val(socketSend(Sock, Data, Data'Length, Written, 0));
    end Socket_Send;

    procedure Socket_Receive(
        Sock: Socket;
        Buf: out char_array;
        Error : out Error_T)
    is
        Received, Ret : unsigned;
    begin
        Ret := socketReceive(Sock, Buf, Buf'Length - 1, Received, 0);
        Error := Error_T'Enum_Val(Ret);
    end Socket_Receive;

    procedure Socket_Shutdown (
        Sock  :     Socket;
        How   :     Socket_Shutdown_Flags;
        Error : out Error_T)
    is
        Ret : unsigned;
    begin
        if Sock = null then
            Error := ERROR_INVALID_PARAMETER;
            return;
        end if;

        Os_Acquire_Mutex (Net_Mutex);
        Ret := Tcp_Shutdown (Sock, Socket_Shutdown_Flags'Enum_Rep(How));
        Os_Release_Mutex (Net_Mutex);
        
        --@TODO to improve
        if Ret = 0 then
            Error := NO_ERROR;
        else
            Error := ERROR_FAILURE;
        end if;
    end Socket_Shutdown;

    procedure Socket_Close (Sock : in out Socket)
    is
    begin
        socketClose (Sock);
    end Socket_Close;

    procedure Socket_Set_Tx_Buffer_Size (
        Sock : in out Socket;
        Size :        Buffer_Size)
    is begin
        --@TODO check
        Sock.txBufferSize := unsigned_long(Size);
    end Socket_Set_Tx_Buffer_Size;

    procedure Socket_Set_Rx_Buffer_Size (
        Sock : in out Socket;
        Size :        Buffer_Size)
    is begin
        --@TODO check
        Sock.rxBufferSize := unsigned_long(Size);
    end Socket_Set_Rx_Buffer_Size;

    procedure Socket_Bind (
        Sock          : in out Socket;
        Local_Ip_Addr :        IpAddr;
        Local_Port    :        Port) 
    is begin
        Sock.S_localIpAddr := Local_Ip_Addr;
        Sock.S_Local_Port := Local_Port;
    end Socket_Bind;

    procedure Socket_Listen (
        Sock   :     Socket;
        Backlog:     Natural;
        Error  : out Error_T)
    is
        Ret : unsigned;
    begin
        Os_Acquire_Mutex (Net_Mutex);
        Ret := Tcp_Listen (Sock, unsigned(Backlog));
        Os_Release_Mutex (Net_Mutex);
        if Ret /= 0 then
            Error := ERROR_FAILURE;
        else
            Error := NO_ERROR;
        end if;
    end Socket_Listen;

    procedure Socket_Accept (
        Sock           :     Socket;
        Client_Ip_Addr : out IpAddr;
        Client_Port    : out Port;
        Client_Socket  : out Socket)
    is
    begin
        Client_Socket := socketAccept(Sock, Client_Ip_Addr, Client_Port);
    end Socket_Accept;


end Socket_interface;
