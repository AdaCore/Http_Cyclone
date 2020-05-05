package body Tcp_Misc_Binding 
    with SPARK_Mode => Off
is

    procedure Tcp_Change_State(
        Sock      : in out Socket;
        New_State : in     Tcp_State
    )
    is
        procedure tcpUpdateEvents (Sock : in out Socket)
        with
            Import => True,
            Convention => C,
            External_Name => "tcpUpdateEvents";
    begin
        -- Enter CLOSED State?
        if New_State = TCP_STATE_CLOSED then
            -- Check previous state
            if Sock.State = TCP_STATE_LAST_ACK or else
               Sock.State = TCP_STATE_TIME_WAIT then
                -- The connection has been closed properly
                Sock.closed_Flag := 1;
            else
                -- the connection has been reset by the peer
                Sock.reset_Flag := 1;
            end if;
        end if;

        -- Enter the desired state
        Sock.State := New_State;
        -- Update TCP related events
        tcpUpdateEvents(Sock);
    end Tcp_Change_State;


    procedure Tcp_Wait_For_Events (
        Sock       : in out Socket;
        Event_Mask : in     unsigned;
        Timeout    : in     Systime;
        Event      :    out unsigned
    )
    is
        function tcpWaitForEvents (Sock : in out Socket; eventMask : unsigned; timeout : Systime)
        return unsigned
        with
            Import => True,
            Convention => C,
            External_Name => "tcpWaitForEvents";
    begin
        Event := tcpWaitForEvents (Sock, Event_Mask, Timeout);
    end Tcp_Wait_For_Events;

end Tcp_Misc_Binding;