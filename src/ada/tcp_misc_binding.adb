with Interfaces.C; use Interfaces.C;
with Tcp_Type; use Tcp_Type;
with Socket_Types; use Socket_Types;

package body Tcp_Misc_Binding is

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

end Tcp_Misc_Binding;