------------------------------------------------------------------------------
--                              HTTP_Cyclone                                --
--                                                                          --
--                        Copyright (C) 2020, AdaCore                       --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General  Public  License  distributed  with  this  software;   see  file --
-- LICENSE  If not, go to http://www.gnu.org/licenses for a complete copy   --
-- of the license.                                                          --
------------------------------------------------------------------------------

pragma Unevaluated_Use_Of_Old (Allow);
pragma Ada_2020;

with Interfaces.C;  use Interfaces.C;
with Ip;            use Ip;
with Error_H;       use Error_H;
with Common_Type;   use Common_Type;
with Socket_Types;  use Socket_Types;
with Net;           use Net;
with Tcp_Interface; use Tcp_Interface;
with Tcp_Type;      use Tcp_Type;

package Socket_Interface with
   SPARK_Mode
is

   type Ttl_Type is mod 2**8;

   type Host_Resolver is mod 2 ** 6;

   HOST_NAME_RESOLVER_ANY   : Host_Resolver := 0;
   HOST_NAME_RESOLVER_DNS   : Host_Resolver := 1;
   HOST_NAME_RESOLVER_MDNS  : Host_Resolver := 2;
   HOST_NAME_RESOLVER_NBNS  : Host_Resolver := 4;
   HOST_NAME_RESOLVER_LLMNR : Host_Resolver := 8;
   HOST_TYPE_IPV4           : Host_Resolver := 16;
   HOST_TYPE_IPV6           : Host_Resolver := 32;

   ----------------------
   -- Get_Host_By_Name --
   ----------------------

   procedure Get_Host_By_Name
     (Server_Name    :     char_array;
      Server_Ip_Addr : out IpAddr;
      Flags          :     Host_Resolver;
      Error          : out Error_T)
      with
        Depends =>
          (Server_Ip_Addr => (Server_Name, Flags),
           Error          => (Server_Name, Flags)),
        Post =>
          (if Error = NO_ERROR then
             Is_Initialized_Ip(Server_Ip_Addr));

   -----------------
   -- Socket_Open --
   -----------------

   procedure Socket_Open
     (Sock       : out Socket;
      S_Type     :     Socket_Type;
      S_Protocol :     Socket_Protocol)
      with
         Global =>
           (Input  => (Net_Mutex, Socket_Table),
            In_Out => Tcp_Dynamic_Port),
         Depends =>
           (Sock             => (S_Type, S_Protocol, Tcp_Dynamic_Port, Socket_Table),
            Tcp_Dynamic_Port => (S_Type, Tcp_Dynamic_Port),
            null             => Net_Mutex),
         Post =>
           (if Sock /= null then
              Sock.S_Type = S_Type and then
              not Is_Initialized_Ip(Sock.S_Remote_Ip_Addr) and then
              not Is_Initialized_Ip(Sock.S_localIpAddr)),
         Contract_Cases =>
            (S_Type = SOCKET_TYPE_STREAM =>
               (if Sock /= null then
                  Sock.S_Protocol = SOCKET_IP_PROTO_TCP and then
                  Sock.S_Local_Port > 0 and then
                  Sock.State = TCP_STATE_CLOSED),
             S_Type = SOCKET_TYPE_DGRAM =>
               (if Sock /= null then
                  Sock.S_Protocol = SOCKET_IP_PROTO_UDP),
             others =>
               (if Sock /= null then
                  Sock.S_Protocol = S_Protocol));

   ------------------------
   -- Socket_Set_Timeout --
   ------------------------

   procedure Socket_Set_Timeout
      (Sock    : in out Not_Null_Socket;
       Timeout :        Systime)
      with
        Global =>
          (Input => Net_Mutex),
        Depends =>
          (Sock => (Timeout, Sock),
           null => Net_Mutex),
        Post =>
          Model(Sock) = Model(Sock)'Old;

   --------------------
   -- Socket_Set_Ttl --
   --------------------

   procedure Socket_Set_Ttl
      (Sock : in out Not_Null_Socket;
       Ttl  :        Ttl_Type)
      with
        Global =>
          (Input => Net_Mutex),
        Depends =>
          (Sock => (Ttl, Sock),
           null => Net_Mutex),
        Post =>
          Model(Sock) = Model(Sock)'Old;

   ------------------------------
   -- Socket_Set_Multicast_Ttl --
   ------------------------------

   procedure Socket_Set_Multicast_Ttl
      (Sock : in out Not_Null_Socket;
       Ttl  :        Ttl_Type)
      with
        Global =>
          (Input => Net_Mutex),
        Depends =>
          (Sock => (Ttl, Sock),
           null => Net_Mutex),
        Post =>
          Model(Sock) = Model(Sock)'Old;

   --------------------
   -- Socket_Connect --
   --------------------

   procedure Socket_Connect
      (Sock           : in out Not_Null_Socket;
       Remote_Ip_Addr : in     IpAddr;
       Remote_Port    : in     Port;
       Error          :    out Error_T)
      with
        Global =>
          (Input => Net_Mutex),
        Depends =>
          (Sock  => (Sock, Remote_Ip_Addr, Remote_Port),
           Error => (Sock, Remote_Ip_Addr, Remote_Port),
           null  => Net_Mutex),
        Pre =>
          Is_Initialized_Ip (Remote_Ip_Addr) and then
          Remote_Port > 0 and then
          (if Sock.S_Type = SOCKET_TYPE_STREAM then
            Sock.State = TCP_STATE_CLOSED),
        Contract_Cases => (
          Sock.S_Type = SOCKET_TYPE_STREAM =>
               (if Error = NO_ERROR then
                  Sock.S_Type = Sock.S_Type'Old and then
                  Sock.S_Protocol = Sock.S_Protocol'Old and then
                  Is_Initialized_Ip (Sock.S_localIpAddr) and then
                  Sock.S_Local_Port = Sock.S_Local_Port'Old and then
                  Sock.S_Remote_Ip_Addr = Remote_Ip_Addr and then
                  Sock.S_Remote_Port = Remote_Port and then
                  Sock.owned_Flag = True and then
                  (Sock.State = TCP_STATE_ESTABLISHED or else
                   Sock.State = TCP_STATE_CLOSE_WAIT)
               else
                  Sock.S_Type = Sock.S_Type'Old and then
                  Sock.S_Protocol = Sock.S_Protocol'Old),

          Sock.S_Type = SOCKET_TYPE_DGRAM =>
               Error = NO_ERROR and then
               Model(Sock) = (Model(Sock)'Old with delta
                  S_Remote_Ip_Addr => Remote_Ip_Addr,
                  S_Remote_Port  => Remote_Port),

          Sock.S_Type = SOCKET_TYPE_RAW_IP =>
               Error = NO_ERROR and then
               Model(Sock) = (Model(Sock)'Old with delta
                  S_Remote_Ip_Addr => Remote_Ip_Addr),

          others =>
             Model(Sock) = Model(Sock)'Old);

   --------------------
   -- Socket_Send_To --
   --------------------

   procedure Socket_Send_To
      (Sock         : in out Not_Null_Socket;
       Dest_Ip_Addr :        IpAddr;
       Dest_Port    :        Port;
       Data         : in     Send_Buffer;
       Written      :    out Natural;
       Flags        :        unsigned;
       Error        :    out Error_T)
      with
        Global =>
          (Input => Net_Mutex),
        Depends =>
          (Error   => (Sock, Data, Flags, Dest_Ip_Addr, Dest_Port),
           Sock    => (Sock, Data, Flags, Dest_Ip_Addr, Dest_Port),
           Written => (Sock, Data, Flags, Dest_Ip_Addr, Dest_Port),
           null    => Net_Mutex),
        Pre  =>
            (if Sock.S_Type = SOCKET_TYPE_STREAM then
               Is_Initialized_Ip(Sock.S_Remote_Ip_Addr) and then
               Sock.S_Remote_Port > 0 and then
               (Sock.State = TCP_STATE_ESTABLISHED or else
                Sock.State = TCP_STATE_CLOSE_WAIT)
             elsif Sock.S_Type = SOCKET_TYPE_DGRAM then
               Is_Initialized_Ip(Dest_Ip_Addr) and then
               Dest_Port > 0),
        Post =>
            Basic_Model(Sock) = Basic_Model(Sock)'Old and then
            (if Error = NO_ERROR then
               Written <= Data'Length),
        Contract_Cases =>
          (Sock.S_Type = SOCKET_TYPE_STREAM =>
               (if Error = NO_ERROR then
                  (if Sock.State'Old = TCP_STATE_CLOSE_WAIT then
                     Model(Sock) = Model(Sock)'Old
                  elsif Sock.State'Old in TCP_STATE_SYN_RECEIVED
                                        | TCP_STATE_SYN_SENT
                                        | TCP_STATE_ESTABLISHED
                  then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_ESTABLISHED) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSE_WAIT))),
          others => True);

   -----------------
   -- Socket_Send --
   -----------------

   procedure Socket_Send
      (Sock    : in out Not_Null_Socket;
       Data    : in     Send_Buffer;
       Written :    out Natural;
       Flags   :        Socket_Flags;
       Error   :    out Error_T)
      with
        Global =>
          (Input => Net_Mutex),
        Depends =>
          (Error   =>  (Sock, Data, Flags),
           Sock    =>+ (Flags, Data),
           Written =>  (Sock, Data, Flags),
           null    =>  Net_Mutex),
        Pre  =>
          Is_Initialized_Ip(Sock.S_Remote_Ip_Addr) and then
          (if Sock.S_Type = SOCKET_TYPE_STREAM then
            Sock.State = TCP_STATE_ESTABLISHED or else
            Sock.State = TCP_STATE_CLOSE_WAIT or else
            Sock.State = TCP_STATE_SYN_SENT or else
            Sock.State = TCP_STATE_SYN_RECEIVED or else
            Sock.State = TCP_STATE_CLOSED),
        Post =>
            Basic_Model(Sock) = Basic_Model(Sock)'Old and then
            (if Error = NO_ERROR then
               Written <= Data'Length),
        Contract_Cases =>
          (Sock.S_Type = SOCKET_TYPE_STREAM =>
               (if Error = NO_ERROR then
                  (if Sock.State'Old = TCP_STATE_CLOSE_WAIT then
                     Model(Sock) = Model(Sock)'Old
                  elsif Sock.State'Old in TCP_STATE_SYN_RECEIVED
                                        | TCP_STATE_SYN_SENT
                                        | TCP_STATE_ESTABLISHED
                  then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_ESTABLISHED) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSE_WAIT))),
          others => True);

   -----------------------
   -- Socket_Receive_Ex --
   -----------------------

   procedure Socket_Receive_Ex
      (Sock         : in out Not_Null_Socket;
       Src_Ip_Addr  :    out IpAddr;
       Src_Port     :    out Port;
       Dest_Ip_Addr :    out IpAddr;
       Data         :    out Received_Buffer;
       Received     :    out Natural;
       Flags        :        Socket_Flags;
       Error        :    out Error_T)
      with
        Global =>
          (Input => Net_Mutex),
        Depends =>
          (Sock         =>  (Sock, Data, Flags),
           Data         =>  (Sock, Data, Flags),
           Received     =>  (Sock, Data, Flags),
           Src_Ip_Addr  =>  (Sock, Data, Flags),
           Src_Port     =>  (Sock, Data, Flags),
           Dest_Ip_Addr =>  (Sock, Data, Flags),
           Error        =>  (Sock, Data, Flags),
           null         =>  Net_Mutex),
        Pre =>
          Data'Last >= Data'First and then
          (if Sock.S_Type = SOCKET_TYPE_STREAM then
            Sock.State /= TCP_STATE_LISTEN and then
            Is_Initialized_Ip(Sock.S_Remote_Ip_Addr) and then
            Sock.S_Remote_Port > 0
          elsif Sock.S_Type = SOCKET_TYPE_DGRAM then
            Is_Initialized_Ip(Src_Ip_Addr) and then
            Src_Port > 0),
        Post =>
            Basic_Model(Sock) = Basic_Model(Sock)'Old,
        Contract_Cases =>
          (Sock.S_Type = SOCKET_TYPE_STREAM =>
               (if Error = NO_ERROR then
                  (if Sock.State'Old in TCP_STATE_ESTABLISHED
                                      | TCP_STATE_SYN_RECEIVED
                                      | TCP_STATE_SYN_SENT
                  then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_ESTABLISHED) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSE_WAIT)
                  elsif Sock.State'Old = TCP_STATE_CLOSE_WAIT then
                     Model(Sock) = Model(Sock)'Old
                  elsif Sock.State'Old = TCP_STATE_FIN_WAIT_1 then
                     Model(Sock) = Model(Sock)'Old or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_FIN_WAIT_2) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSING) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED)
                  elsif Sock.State'Old in TCP_STATE_FIN_WAIT_2
                                        | TCP_STATE_CLOSING
                  then
                     Model(Sock) = Model(Sock)'Old or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED)
                  elsif Sock.State'Old = TCP_STATE_CLOSED then
                     Model(Sock) = Model(Sock)'Old
                  elsif Sock.State'Old = TCP_STATE_TIME_WAIT or else
                        Sock.State'Old = TCP_STATE_LAST_ACK
                  then
                     Model(Sock) = Model(Sock)'Old or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED)
                  ) and then
                  Received > 0

               elsif Error = ERROR_END_OF_STREAM then
                  (if Sock.State'Old in TCP_STATE_ESTABLISHED
                                      | TCP_STATE_SYN_RECEIVED
                                      | TCP_STATE_SYN_SENT
                                      | TCP_STATE_CLOSE_WAIT
                  then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSE_WAIT)
                  elsif Sock.State'Old = TCP_STATE_CLOSING then
                     Model(Sock) = Model(Sock)'Old or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED)
                  elsif Sock.State'Old = TCP_STATE_TIME_WAIT then
                     Model(Sock) = Model(Sock)'Old or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED)
                  elsif Sock.State'Old = TCP_STATE_FIN_WAIT_2 then
                     Model(Sock) = Model(Sock)'Old or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED)
                  elsif Sock.State'Old = TCP_STATE_FIN_WAIT_1 then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSING) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_FIN_WAIT_2) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED)
                  ) and then
                  Received = 0
               ),
           Sock.S_Type = SOCKET_TYPE_DGRAM => True,
           others =>
               Error = ERROR_INVALID_SOCKET and then
               Received = 0);

   --------------------
   -- Socket_Receive --
   --------------------

   procedure Socket_Receive
      (Sock     : in out Not_Null_Socket;
       Data     :    out Received_Buffer;
       Received :    out Natural;
       Flags    :        Socket_Flags;
       Error    :    out Error_T)
      with
        Global =>
          (Input => Net_Mutex),
        Depends =>
          (Sock     =>  (Sock, Data, Flags),
           Data     =>  (Sock, Data, Flags),
           Error    =>  (Sock, Data, Flags),
           Received =>  (Sock, Data, Flags),
           null     =>  Net_Mutex),
        Pre =>
          Is_Initialized_Ip(Sock.S_Remote_Ip_Addr) and then
          Data'Last >= Data'First and then
          (if Sock.S_Type = SOCKET_TYPE_STREAM then
            Sock.State /= TCP_STATE_LISTEN),
        Post =>
            Basic_Model (Sock) = Basic_Model (Sock)'Old,
        Contract_Cases =>
          (Sock.S_Type = SOCKET_TYPE_STREAM =>
               (if Error = NO_ERROR then
                  (if Sock.State'Old in TCP_STATE_ESTABLISHED
                                      | TCP_STATE_SYN_RECEIVED
                                      | TCP_STATE_SYN_SENT
                  then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_ESTABLISHED) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSE_WAIT)
                  elsif Sock.State'Old = TCP_STATE_CLOSE_WAIT then
                     Model(Sock) = Model(Sock)'Old
                  elsif Sock.State'Old = TCP_STATE_FIN_WAIT_1 then
                     Model(Sock) = Model(Sock)'Old or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_FIN_WAIT_2) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSING) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED)
                  elsif Sock.State'Old in TCP_STATE_FIN_WAIT_2
                                        | TCP_STATE_CLOSING
                  then
                     Model(Sock) = Model(Sock)'Old or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED)
                  elsif Sock.State'Old = TCP_STATE_CLOSED then
                     Model(Sock) = Model(Sock)'Old
                  elsif Sock.State'Old = TCP_STATE_TIME_WAIT or else
                        Sock.State'Old = TCP_STATE_LAST_ACK
                  then
                     Model(Sock) = Model(Sock)'Old or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED)
                  ) and then
                  Received > 0

               elsif Error = ERROR_END_OF_STREAM then
                  (if Sock.State'Old in TCP_STATE_ESTABLISHED
                                      | TCP_STATE_SYN_RECEIVED
                                      | TCP_STATE_SYN_SENT
                                      | TCP_STATE_CLOSE_WAIT
                  then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSE_WAIT)
                  elsif Sock.State'Old = TCP_STATE_CLOSING then
                     Model(Sock) = Model(Sock)'Old or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED)
                  elsif Sock.State'Old = TCP_STATE_TIME_WAIT then
                     Model(Sock) = Model(Sock)'Old or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED)
                  elsif Sock.State'Old = TCP_STATE_FIN_WAIT_2 then
                     Model(Sock) = Model(Sock)'Old or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED)
                  elsif Sock.State'Old = TCP_STATE_FIN_WAIT_1 then
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSING) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_TIME_WAIT) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_FIN_WAIT_2) or else
                     Model(Sock) = (Model(Sock)'Old with delta
                        S_State => TCP_STATE_CLOSED)
                  ) and then
                  Received = 0
               ),
           Sock.S_Type = SOCKET_TYPE_DGRAM => True,
           others =>
               Error = ERROR_INVALID_SOCKET and then
               Received = 0);

   ---------------------
   -- Socket_Shutdown --
   ---------------------

   procedure Socket_Shutdown
      (Sock  : in out Not_Null_Socket;
       How   :        Socket_Shutdown_Flags;
       Error :    out Error_T)
      with
        Global =>
          (Input => Net_Mutex),
        Depends =>
          (Sock  => (Sock, How),
           Error => (Sock, How),
           null  => Net_Mutex),
        Pre =>
          Sock.S_Type = SOCKET_TYPE_STREAM and then
          Is_Initialized_Ip(Sock.S_Remote_Ip_Addr) and then
          Sock.State /= TCP_STATE_LISTEN,
        Post =>
          (if Error = NO_ERROR then
            (if How = SOCKET_SD_SEND then
               (if Sock.State'Old = TCP_STATE_CLOSE_WAIT then
                  Model(Sock) = (Model(Sock)'Old with delta
                     S_State => TCP_STATE_CLOSED)
               else
                  (Sock.State'Old = TCP_STATE_SYN_SENT and then
                     Model(Sock) = Model(Sock)'Old) or else
                  Model(Sock) = (Model(Sock)'Old with delta
                     S_State => TCP_STATE_FIN_WAIT_2) or else
                  Model(Sock) = (Model(Sock)'Old with delta
                     S_State => TCP_STATE_TIME_WAIT) or else
                  Model(Sock) = (Model(Sock)'Old with delta
                     S_State => TCP_STATE_CLOSED,
                     S_Reset_Flag => True) or else
                  Model(Sock) = (Model(Sock)'Old with delta
                     S_State => TCP_STATE_CLOSED)))
            and then
            (if How = SOCKET_SD_RECEIVE then
               -- The connection can have been reset
               Model(Sock) = (Model(Sock)'Old with delta
                  S_State => TCP_STATE_CLOSED,
                  S_Reset_Flag => True) or else
               (if Sock.State'Old in TCP_STATE_SYN_SENT
                                   | TCP_STATE_SYN_RECEIVED
                                   | TCP_STATE_ESTABLISHED
               then
                  Model(Sock) = (Model(Sock)'Old with delta
                     S_State => TCP_STATE_ESTABLISHED) or else
                  Model(Sock) = (Model(Sock)'Old with delta
                     S_State => TCP_STATE_CLOSE_WAIT)
               elsif Sock.State'Old = TCP_STATE_CLOSE_WAIT then
                  Model(Sock) = Model(Sock)'Old
               elsif Sock.State'Old = TCP_STATE_LAST_ACK then
                  Model(Sock) = Model(Sock)'Old or else
                  Model(Sock) = (Model(Sock)'Old with delta
                     S_State => TCP_STATE_CLOSED)
               elsif Sock.State'Old = TCP_STATE_CLOSED then
                  Model(Sock) = Model(Sock)'Old
               else
                  Model(Sock) = (Model(Sock)'Old with delta
                     S_State => TCP_STATE_CLOSING) or else
                  Model(Sock) = (Model(Sock)'Old with delta
                     S_State => TCP_STATE_TIME_WAIT) or else
                  Model(Sock) = (Model(Sock)'Old with delta
                     S_State => TCP_STATE_CLOSED)))
            and then
            (if How = SOCKET_SD_BOTH then
               -- The connection can have been reset
               Model(Sock) = (Model(Sock)'Old with delta
                  S_State => TCP_STATE_CLOSED,
                  S_Reset_Flag => True) or else
               -- Special case for the function SYN_SENT
               (Sock.State'Old = TCP_STATE_SYN_SENT and then
                  (Model(Sock) = (Model(Sock)'Old with delta
                     S_State => TCP_STATE_ESTABLISHED) or else
                  Model(Sock) = (Model(Sock)'Old with delta
                     S_State => TCP_STATE_CLOSE_WAIT))) or else
               Model(Sock) = (Model(Sock)'Old with delta
                  S_State => TCP_STATE_FIN_WAIT_2) or else
               Model(Sock) = (Model(Sock)'Old with delta
                  S_State => TCP_STATE_TIME_WAIT) or else
               Model(Sock) = (Model(Sock)'Old with delta
                  S_State => TCP_STATE_CLOSE_WAIT) or else
               Model(Sock) = (Model(Sock)'Old with delta
                  S_State => TCP_STATE_LAST_ACK) or else
               Model(Sock) = (Model(Sock)'Old with delta
                  S_State => TCP_STATE_CLOSING) or else
               Model(Sock) = (Model(Sock)'Old with delta
                  S_State => TCP_STATE_CLOSED))
           else
             Basic_Model (Sock) = Basic_Model (Sock)'Old);

   ------------------
   -- Socket_Close --
   ------------------

   procedure Socket_Close
      (Sock : in out Socket)
      with
        Global  => (Input => Net_Mutex),
        Depends => (Sock =>+ null,
                    null => Net_Mutex),
        Pre     => Sock /= null and then
                   Sock.S_Type /= SOCKET_TYPE_UNUSED,
        Post    => Sock = null;

   -------------------------------
   -- Socket_Set_Tx_Buffer_Size --
   -------------------------------

   procedure Socket_Set_Tx_Buffer_Size
      (Sock : in out Not_Null_Socket;
       Size :        Tx_Buffer_Size)
      with
        Depends => (Sock => (Size, Sock)),
        Pre => Sock.S_Type = SOCKET_TYPE_STREAM and then
               not Is_Initialized_Ip(Sock.S_Remote_Ip_Addr) and then
               Sock.State = TCP_STATE_CLOSED,
        Post =>
          Model(Sock) = Model(Sock)'Old;

   -------------------------------
   -- Socket_Set_Rx_Buffer_Size --
   -------------------------------

   procedure Socket_Set_Rx_Buffer_Size
      (Sock : in out Not_Null_Socket;
       Size :        Rx_Buffer_Size)
      with
        Depends => (Sock => (Size, Sock)),
        Pre =>
          Sock.S_Type = SOCKET_TYPE_STREAM and then
          not Is_Initialized_Ip (Sock.S_Remote_Ip_Addr) and then
          Sock.State = TCP_STATE_CLOSED,
        Post =>
            Model(Sock) = Model(Sock)'Old;

   -----------------
   -- Socket_Bind --
   -----------------

   procedure Socket_Bind
      (Sock          : in out Not_Null_Socket;
       Local_Ip_Addr :        IpAddr;
       Local_Port    :        Port)
      with
       Global => (Proof_In => IP_ADDR_ANY),
       Depends => (Sock => (Sock, Local_Ip_Addr, Local_Port)),
       Pre =>
         not Is_Initialized_Ip(Sock.S_Remote_Ip_Addr) and then
         not Is_Initialized_Ip(Sock.S_localIpAddr) and then
         (Is_Initialized_Ip(Local_Ip_Addr) or else
          Local_Ip_Addr = IP_ADDR_ANY) and then
         (Sock.S_Type = SOCKET_TYPE_STREAM or else
          Sock.S_Type = SOCKET_TYPE_DGRAM),
       Post =>
         Model(Sock) = (Model(Sock)'Old with delta
            S_localIpAddr => Local_Ip_Addr,
            S_Local_Port  => Local_Port);

   -------------------
   -- Socket_Listen --
   -------------------

   procedure Socket_Listen
      (Sock    : in out Not_Null_Socket;
       Backlog :        Natural)
       -- Error   :    out Error_T)
      with
        Global => (Input    => Net_Mutex,
                   Proof_In => IP_ADDR_ANY),
        Depends =>
          (Sock  =>+ Backlog,
           null => Net_Mutex),
        Pre =>
          Sock.S_Type = SOCKET_TYPE_STREAM and then
          (Is_Initialized_Ip(Sock.S_localIpAddr) or else
           Sock.S_localIpAddr = IP_ADDR_ANY) and then
          not Is_Initialized_Ip(Sock.S_Remote_Ip_Addr) and then
          Sock.State = TCP_STATE_CLOSED,
        Post =>
          Model(Sock) = (Model(Sock)'Old with delta
               S_State => TCP_STATE_LISTEN);

   -------------------
   -- Socket_Accept --
   -------------------

   procedure Socket_Accept
      (Sock           : in out Not_Null_Socket;
       Client_Ip_Addr :    out IpAddr;
       Client_Port    :    out Port;
       Client_Socket  :    out Socket)
      with
       Global =>
         (Input    => (Net_Mutex, Socket_Table),
          In_Out   => Tcp_Dynamic_Port,
          Proof_In => IP_ADDR_ANY),
       Depends =>
          (Sock             => (Sock, Tcp_Dynamic_Port, Socket_Table),
           Client_Ip_Addr   => (Sock, Tcp_Dynamic_Port, Socket_Table),
           Client_Port      => (Sock, Tcp_Dynamic_Port, Socket_Table),
           Client_Socket    => (Sock, Tcp_Dynamic_Port, Socket_Table),
           Tcp_Dynamic_Port =>+ (Sock, Socket_Table),
           null             => Net_Mutex),
       Pre => Sock.S_Type = SOCKET_TYPE_STREAM and then
              (Is_Initialized_Ip(Sock.S_localIpAddr) or else
               Sock.S_localIpAddr = IP_ADDR_ANY) and then
              not Is_Initialized_Ip(Sock.S_Remote_Ip_Addr) and then
              Sock.State = TCP_STATE_LISTEN and then
              Sock.S_Local_Port > 0,
       Post =>
            Model(Sock) = Model(Sock)'Old and then
            (if Client_Socket /= null then
               Client_Port > 0 and then
               Is_Initialized_Ip (Client_Ip_Addr) and then
               Client_Socket.S_Type = SOCKET_TYPE_STREAM and then
               Client_Socket.S_Protocol = SOCKET_IP_PROTO_TCP and then
               Is_Initialized_Ip(Client_Socket.S_localIpAddr) and then
               Client_Socket.S_Local_Port = Sock.S_Local_Port and then
               Client_Socket.S_Remote_Ip_Addr = Client_Ip_Addr and then
               Client_Socket.S_Remote_Port = Client_Port and then
               Client_Socket.owned_Flag = True and then
               Client_Socket.State = TCP_STATE_SYN_RECEIVED);

end Socket_Interface;
