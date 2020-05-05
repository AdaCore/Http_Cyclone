with Interfaces.C; use Interfaces.C;
with Tcp_Type; use Tcp_Type;
with Socket_Types; use Socket_Types;

package Tcp_Misc_Binding is

    procedure Tcp_Change_State(
        Sock      : in out Socket;
        New_State : in     Tcp_State
    )
    with
        Depends => (Sock => (Sock, New_State)),
        Pre => Sock /= null;

end Tcp_Misc_Binding;