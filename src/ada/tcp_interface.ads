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

pragma Ada_2020;
pragma Unevaluated_Use_Of_Old (Allow);

with Common_Type;  use Common_Type;
with Error_H;      use Error_H;
with Interfaces.C; use Interfaces.C;
with Ip;           use Ip;
with Net;          use Net;
with Socket_Types; use Socket_Types;
with Tcp_Type;     use Tcp_Type;

package Tcp_Interface
  with SPARK_Mode
is
   --  Ephemeral ports are used for dynamic port assignment
   Tcp_Dynamic_Port : Port;

   function Tcp_Init return Error_T
      with
         Import => True,
         Convention => C,
         External_Name => "tcpInit";

   procedure Tcp_Get_Dynamic_Port
      (P : out Port)
      with
        Global =>
          (In_Out => Tcp_Dynamic_Port),
        Depends =>
          (P                => Tcp_Dynamic_Port,
           Tcp_Dynamic_Port => Tcp_Dynamic_Port),
     Post =>
       P in SOCKET_EPHEMERAL_PORT_MIN .. SOCKET_EPHEMERAL_PORT_MAX and then
       Tcp_Dynamic_Port in
         SOCKET_EPHEMERAL_PORT_MIN .. SOCKET_EPHEMERAL_PORT_MAX;

   procedure Tcp_Connect
      (Sock           : in out Not_Null_Socket;
       Remote_Ip_Addr :        IpAddr;
       Remote_Port    :        Port;
       Error          :    out Error_T)
      with
        Depends =>
          (Sock  =>+ (Remote_Ip_Addr, Remote_Port),
           Error => (Sock, Remote_Port, Remote_Ip_Addr)),
        Pre => Sock.S_Type = SOCKET_TYPE_STREAM and then
               Is_Initialized_Ip (Remote_Ip_Addr) and then
               Remote_Port > 0 and then
               Sock.State = TCP_STATE_CLOSED,
        Post =>
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
               Sock.S_Protocol = Sock.S_Protocol'Old);

   procedure Tcp_Listen
      (Sock    : in out Not_Null_Socket;
       Backlog :        unsigned)
      with
        Depends =>
          (Sock  =>+ Backlog),
        Pre => Sock.S_Type = SOCKET_TYPE_STREAM and then
               Sock.State = TCP_STATE_CLOSED,
        Post =>
          Model (Sock) = (Model (Sock)'Old with delta
            S_State => TCP_STATE_LISTEN);

   procedure Tcp_Accept
      (Sock           : in out Not_Null_Socket;
       Client_Ip_Addr :    out IpAddr;
       Client_Port    :    out Port;
       Client_Socket  :    out Socket)
      with
        Global =>
          (Input  => (Net_Mutex, Socket_Table),
           In_Out => Tcp_Dynamic_Port),
        Depends =>
          (Sock             =>+ (Tcp_Dynamic_Port, Socket_Table),
           Client_Ip_Addr   =>  (Sock, Tcp_Dynamic_Port, Socket_Table),
           Client_Port      =>  (Sock, Tcp_Dynamic_Port, Socket_Table),
           Client_Socket    =>  (Sock, Tcp_Dynamic_Port, Socket_Table),
           Tcp_Dynamic_Port =>+ (Socket_Table, Sock),
           null             =>  Net_Mutex),
        Pre => Sock.S_Type = SOCKET_TYPE_STREAM and then
        --  Ensure the socket was previously placed
        --  in the listening state
               Sock.State = TCP_STATE_LISTEN and then
               Sock.S_Local_Port > 0,
        Post =>
            Model (Sock) = Model (Sock)'Old and then
            (if Client_Socket /= null then
               Client_Port > 0 and then
               Is_Initialized_Ip (Client_Ip_Addr) and then
               Client_Socket.S_Type = SOCKET_TYPE_STREAM and then
               Client_Socket.S_Protocol = SOCKET_IP_PROTO_TCP and then
               Is_Initialized_Ip (Client_Socket.S_localIpAddr) and then
               Client_Socket.S_Local_Port = Sock.S_Local_Port and then
               Client_Socket.S_Remote_Ip_Addr = Client_Ip_Addr and then
               Client_Socket.S_Remote_Port = Client_Port and then
               Client_Socket.owned_Flag = True and then
               Client_Socket.State = TCP_STATE_SYN_RECEIVED);

   procedure Tcp_Send
      (Sock    : in out Not_Null_Socket;
       Data    :        Send_Buffer;
       Written :    out Natural;
       Flags   :        unsigned;
       Error   :    out Error_T)
      with
        Depends =>
          (Sock    =>+ (Data, Flags),
           Written =>  (Sock, Data, Flags),
           Error   =>  (Sock, Data, Flags)),
        Pre => Sock.S_Type = SOCKET_TYPE_STREAM and then
               (Sock.State = TCP_STATE_ESTABLISHED or else
                Sock.State = TCP_STATE_SYN_RECEIVED or else
                Sock.State = TCP_STATE_SYN_SENT or else
                Sock.State = TCP_STATE_CLOSE_WAIT or else
                Sock.State = TCP_STATE_CLOSED),
        Post =>
          Basic_Model (Sock) = Basic_Model (Sock)'Old and then
          (if Sock.State'Old = TCP_STATE_CLOSED then
               Error /= NO_ERROR) and then
          (if Error = NO_ERROR then
               (if Sock.State'Old = TCP_STATE_CLOSE_WAIT then
                  Model (Sock) = Model (Sock)'Old
               elsif Sock.State'Old in TCP_STATE_SYN_RECEIVED
                                     | TCP_STATE_SYN_SENT
                                     | TCP_STATE_ESTABLISHED
               then
                  Model (Sock) = (Model (Sock)'Old with delta
                     S_State => TCP_STATE_ESTABLISHED) or else
                  Model (Sock) = (Model (Sock)'Old with delta
                     S_State => TCP_STATE_CLOSE_WAIT))
               and then
               Written <= Data'Length);

   procedure Tcp_Receive
      (Sock     : in out Not_Null_Socket;
       Data     :    out Received_Buffer;
       Received :    out Natural;
       Flags    :        unsigned;
       Error    :    out Error_T)
      with
        Depends =>
          (Error    =>  (Sock, Data, Flags),
           Sock     =>+ (Flags, Data),
           Data     =>  (Sock, Data, Flags),
           Received =>  (Sock, Data, Flags)),
        Pre =>
          Sock.S_Type = SOCKET_TYPE_STREAM and then
          Sock.State /= TCP_STATE_LISTEN and then
          Is_Initialized_Ip (Sock.S_Remote_Ip_Addr) and then
          Data'Last >= Data'First,
        Post =>
          Basic_Model (Sock) = Basic_Model (Sock)'Old and then
          (if Sock.State'Old = TCP_STATE_CLOSED and then
              Sock.reset_Flag'Old = True then
            Error /= ERROR_END_OF_STREAM and then
            Error /= NO_ERROR) and then
          -- If the function succeed
          (if Error = NO_ERROR then
            (if Sock.State'Old in TCP_STATE_ESTABLISHED
                                | TCP_STATE_SYN_RECEIVED
                                | TCP_STATE_SYN_SENT
            then
               Model (Sock) = (Model (Sock)'Old with delta
                  S_State => TCP_STATE_ESTABLISHED) or else
               Model (Sock) = (Model (Sock)'Old with delta
                  S_State => TCP_STATE_CLOSE_WAIT)
            elsif Sock.State'Old = TCP_STATE_FIN_WAIT_1 then
               Model (Sock) = Model (Sock)'Old or else
               Model (Sock) = (Model (Sock)'Old with delta
                  S_State => TCP_STATE_FIN_WAIT_2) or else
               Model (Sock) = (Model (Sock)'Old with delta
                  S_State => TCP_STATE_TIME_WAIT) or else
               Model (Sock) = (Model (Sock)'Old with delta
                  S_State => TCP_STATE_CLOSING)
            elsif Sock.State'Old = TCP_STATE_FIN_WAIT_2 then
               Model (Sock) = Model (Sock)'Old or else
               Model (Sock) = (Model (Sock)'Old with delta
                  S_State => TCP_STATE_TIME_WAIT)
            elsif Sock.State'Old in TCP_STATE_CLOSE_WAIT
                                   | TCP_STATE_CLOSING
                                   | TCP_STATE_TIME_WAIT
                                   | TCP_STATE_LAST_ACK
                                   | TCP_STATE_CLOSED
            then
               Model (Sock) = Model (Sock)'Old
                  ) and then
             Received > 0

         --  If there is no more data to receive.
         elsif Error = ERROR_END_OF_STREAM then
            (if Sock.State'Old in TCP_STATE_ESTABLISHED
                                | TCP_STATE_SYN_RECEIVED
                                | TCP_STATE_SYN_SENT
                                | TCP_STATE_CLOSE_WAIT
            then
               Model (Sock) = (Model (Sock)'Old with delta
                  S_State => TCP_STATE_CLOSE_WAIT)
            elsif Sock.State'Old in TCP_STATE_FIN_WAIT_1
                                   | TCP_STATE_CLOSING
            then
               Model (Sock) = (Model (Sock)'Old with delta
                  S_State => TCP_STATE_CLOSING) or else
               Model (Sock) = (Model (Sock)'Old with delta
                  S_State => TCP_STATE_TIME_WAIT)
            elsif Sock.State'Old = TCP_STATE_FIN_WAIT_2 then
               Model (Sock) = Model (Sock)'Old or else
               Model (Sock) = (Model (Sock)'Old with delta
                  S_State => TCP_STATE_TIME_WAIT)
            elsif Sock.State'Old = TCP_STATE_TIME_WAIT then
               Model (Sock) = (Model (Sock)'Old with delta
                  S_State => TCP_STATE_TIME_WAIT)
            elsif Sock.State'Old = TCP_STATE_CLOSED then
               Model (Sock) = Model (Sock)'Old
            ) and then
             Received = 0);

   procedure Tcp_Shutdown
      (Sock  : in out Not_Null_Socket;
       How   :        Socket_Shutdown_Flags;
       Error :    out Error_T)
      with
        Depends =>
          (Sock  =>+ How,
           Error =>  (Sock, How)),
        Pre => Sock.S_Type = SOCKET_TYPE_STREAM and then
               Sock.State /= TCP_STATE_LISTEN,
        Post =>
         (if How in SOCKET_SD_SEND | SOCKET_SD_BOTH and then
             Sock.State'Old = TCP_STATE_CLOSED
         then
            Error = ERROR_NOT_CONNECTED)
         and then
         (if Error = NO_ERROR then
            (if How = SOCKET_SD_SEND then
               (if Sock.State'Old = TCP_STATE_SYN_SENT then
                  Model (Sock) = Model (Sock)'Old
                elsif Sock.State'Old = TCP_STATE_CLOSE_WAIT then
                  Model (Sock) = (Model (Sock)'Old with delta
                     S_State => TCP_STATE_CLOSED)
                -- All other states. We could be more precise, but
                -- it's not needed at this point.
                -- And I find this representation clearer because we
                -- see all the final state whatever is the old state.
                else
                  Model (Sock) = (Model (Sock)'Old with delta
                     S_State => TCP_STATE_FIN_WAIT_2) or else
                  Model (Sock) = (Model (Sock)'Old with delta
                     S_State => TCP_STATE_TIME_WAIT) or else
                  Model (Sock) = (Model (Sock)'Old with delta
                     S_State => TCP_STATE_CLOSED) or else
                  Model (Sock) = (Model (Sock)'Old with delta
                     S_State => TCP_STATE_CLOSED,
                     S_Reset_Flag => True)))
            and then
            (if How = SOCKET_SD_RECEIVE then
               --  The connection can have been reset
               Model (Sock) = (Model (Sock)'Old with delta
                  S_State => TCP_STATE_CLOSED,
                  S_Reset_Flag => True) or else
               (if Sock.State'Old in TCP_STATE_SYN_SENT
                                   | TCP_STATE_SYN_RECEIVED
                                   | TCP_STATE_ESTABLISHED
               then
                  Model (Sock) = (Model (Sock)'Old with delta
                     S_State => TCP_STATE_ESTABLISHED) or else
                  Model (Sock) = (Model (Sock)'Old with delta
                     S_State => TCP_STATE_CLOSE_WAIT)
               elsif Sock.State'Old = TCP_STATE_FIN_WAIT_1 then
                  Model (Sock) = (Model (Sock)'Old with delta
                     S_State => TCP_STATE_CLOSING) or else
                  Model (Sock) = (Model (Sock)'Old with delta
                     S_State => TCP_STATE_TIME_WAIT)
               elsif Sock.State'Old = TCP_STATE_FIN_WAIT_2 then
                  Model (Sock) = (Model (Sock)'Old with delta
                     S_State => TCP_STATE_TIME_WAIT)
               else
                  Model (Sock) = Model (Sock)'Old))
            and then
            (if How = SOCKET_SD_BOTH then
               --  The connection can have been reset
               Model (Sock) = (Model (Sock)'Old with delta
                  S_State => TCP_STATE_CLOSED,
                  S_Reset_Flag => True) or else
               (if Sock.State'Old = TCP_STATE_SYN_SENT then
                  Model (Sock) = (Model (Sock)'Old with delta
                     S_State => TCP_STATE_ESTABLISHED) or else
                  Model (Sock) = (Model (Sock)'Old with delta
                     S_State => TCP_STATE_CLOSE_WAIT)
               else
                  Model (Sock) = (Model (Sock)'Old with delta
                     S_State => TCP_STATE_FIN_WAIT_2) or else
                  Model (Sock) = (Model (Sock)'Old with delta
                     S_State => TCP_STATE_TIME_WAIT) or else
                  Model (Sock) = (Model (Sock)'Old with delta
                     S_State => TCP_STATE_CLOSE_WAIT) or else
                  Model (Sock) = (Model (Sock)'Old with delta
                     S_State => TCP_STATE_LAST_ACK) or else
                  Model (Sock) = (Model (Sock)'Old with delta
                     S_State => TCP_STATE_CLOSING) or else
                  Model (Sock) = (Model (Sock)'Old with delta
                     S_State => TCP_STATE_CLOSED)))
         else
            Basic_Model (Sock) = Basic_Model (Sock)'Old);

   procedure Tcp_Abort
      (Sock  : in out Socket;
       Error :    out Error_T)
      with
        Depends => (Sock => Sock,
                    Error => Sock),
        Pre => Sock /= null and then
               Sock.S_Type = SOCKET_TYPE_STREAM,
        Post => Sock = null;

   procedure Tcp_Kill_Oldest_Connection
      (Sock : out Socket)
      with
        Depends => (Sock => null),
        Post =>
           (if Sock /= null then
              Sock.S_Type = SOCKET_TYPE_UNUSED);

   procedure Tcp_Get_State
     (Sock : not null access constant Socket_Struct;
      State : out Tcp_State)
      with
        Global  => (Input => Net_Mutex),
        Depends =>
          ((State) => Sock,
           null  => Net_Mutex),
        Pre => Sock.S_Type = SOCKET_TYPE_STREAM,
        Post =>
          State = Sock.State and then
          Model (Sock) = Model (Sock)'Old;

end Tcp_Interface;
