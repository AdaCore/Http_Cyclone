with System;
with Socket_Binding; use Socket_Binding;

package body Socket_Helper 
    with SPARK_Mode => Off
is

    procedure Get_Socket_From_Table (
        Index : in Socket_Type_Index; 
        Sock : out Socket)
    is 
        function getSocketFromTable (index : unsigned) return Socket
        with
            Import => True,
            Convention => C,
            External_Name => "getSocketFromTable";
    begin
        Sock := getSocketFromTable(unsigned(Index));
    end Get_Socket_From_Table;


    -- Temporaire, à supprimer.
    -- Juste pour faire tourner gnatprove pour le moment
    procedure Get_Host_By_Name_H (
        Server_Name    : char_array; 
        Server_Ip_Addr : out IpAddr;
        Flags : unsigned;
        Error : out Error_T)
    is begin
        Error := Error_T'Enum_Val(getHostByName(System.Null_Address, Server_Name, Server_Ip_Addr, Flags));
    end Get_Host_By_Name_H;

end Socket_Helper;