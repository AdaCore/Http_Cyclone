with Socket_Types; use Socket_Types;
with Interfaces.C; use Interfaces.C;
with Error_H; use Error_H;
with Ip; use Ip;

package Socket_Helper 
    with SPARK_Mode
is

    procedure Get_Socket_From_Table (
        Index : in Socket_Type_Index; 
        Sock : out Socket)
    with
        Depends => (Sock => Index),
        Post => Sock /= null;

    procedure Get_Host_By_Name_H (
        Server_Name    : char_array; 
        Server_Ip_Addr : out IpAddr;
        Flags : unsigned;
        Error : out Error_T)
    with
        Post => (
            if Error = NO_ERROR then
                Server_Ip_Addr.length > 0);

end Socket_Helper;