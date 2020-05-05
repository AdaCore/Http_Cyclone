with Tcp_Type; use Tcp_Type;
with Interfaces.C; use Interfaces.C;
with Socket_Types; use Socket_Types;
with Common_Type; use Common_Type;

package Tcp_Misc_Binding 
    with SPARK_Mode
is

    procedure Tcp_Change_State(
        Sock      : in out Socket;
        New_State : in     Tcp_State
    )
    with
        Depends => (Sock => (Sock, New_State)),
        Pre => Sock /= null;

    procedure Tcp_Wait_For_Events (
        Sock       : in out Socket;
        Event_Mask : in     unsigned;
        Timeout    : in     Systime;
        Event      :    out unsigned
    )
    with
        Depends => (
            Sock =>+ (Event_Mask, Timeout),
            Event => (Event_Mask, Timeout)),
        Pre => Sock /= null;

    procedure Tcp_Write_Tx_Buffer (
        Sock    : in out Socket;
        Seq_Num :        unsigned;
        Data    :        char_array;
        Length  :        unsigned
    )
    with
        Import => True,
        Convention => C,
        External_Name => "tcpWriteTxBuffer";

    procedure Tcp_Delete_Control_Block (
        Sock : in out Socket
    )
    with
        Import => True,
        Convention => C,
        External_Name => "tcpDeleteControlBlock";

end Tcp_Misc_Binding;