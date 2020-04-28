with Common_Type; use Common_Type;
with Interfaces.C; use Interfaces.C;
with System;
with Socket_Type; use Socket_Type;

package Udp_Binding is

    function Udp_Init return unsigned
    with
        Import => True,
        Convention => C,
        External_Name => "udpInit";

    function Udp_Get_Dynamic_Port
    return Port
    with
        Import => True,
        Convention => C,
        External_Name => "udpGetDynamicPort";

    function Udp_Process_Datagram (
        N_Interface : System.Address;
        PseudoHeader : System.Address;
        Buffer : System.Address;
        Offset : unsigned;
        Ancillary : System.Address
    )
    return unsigned
    with
        Import => True,
        Convention => C,
        External_Name => "udpProcessDatagram";

    function Udp_Send_Datagram (
        Sock : Socket;
        Dest_Ip_Addr : System.Address;
        Dest_Port : Port;
        Data : char_array;
        Length : unsigned;
        Written : out unsigned;
        Flags : unsigned
    )
    return unsigned
    with
        Import => True,
        Convention => C,
        External_Name => "udpSendDatagram";

end Udp_Binding;