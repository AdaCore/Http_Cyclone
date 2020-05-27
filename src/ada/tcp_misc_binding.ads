pragma Unevaluated_Use_Of_Old (Allow);

with Common_Type;  use Common_Type;
with Error_H;      use Error_H;
with Interfaces.C; use Interfaces.C;
with Socket_Types; use Socket_Types;
with Tcp_Type;     use Tcp_Type;

package Tcp_Misc_Binding with
   SPARK_Mode
is

   procedure Tcp_Change_State
      (Sock      : in out Not_Null_Socket;
       New_State : in     Tcp_State)
      with
        Depends => (Sock =>+ New_State),
        Post => Model(Sock) = Model(Sock)'Old'Update
                              (S_State => New_State);

   procedure Tcp_Wait_For_Events
      (Sock       : in out Not_Null_Socket;
       Event_Mask : in     Socket_Event;
       Timeout    : in     Systime;
       Event      :    out Socket_Event)
      with
         Depends =>
           (Sock  =>+ (Event_Mask, Timeout),
            Event =>  (Event_Mask, Timeout)),
         Pre  => Event_Mask /= 0,
         Post =>
            (if (Event_Mask and SOCKET_EVENT_CONNECTED) /= 0 then
               (if Event = SOCKET_EVENT_CONNECTED then
                     (if Sock.State'Old = TCP_STATE_SYN_SENT then
                        Model(Sock) = Model(Sock)'Old'Update
                              (S_State => TCP_STATE_ESTABLISHED))))
            and then
            (if (Event_Mask and SOCKET_EVENT_CLOSED) /= 0 then
               (if Event = SOCKET_EVENT_CLOSED then
                  (if Sock.State'Old = TCP_STATE_SYN_SENT then
                     -- Maybe here it's not the correct state returned
                     -- @TODO investigate
                     Model(Sock) = Model(Sock)'Old'Update
                        (S_State => TCP_STATE_CLOSED))))
            and then
            (if (Event_Mask and SOCKET_EVENT_TX_READY) /=0 then
               (if Event = SOCKET_EVENT_TX_READY then
                  Model (Sock) = Model (Sock)'Old));

   procedure Tcp_Write_Tx_Buffer
      (Sock    :        Not_Null_Socket;
       Seq_Num :        unsigned;
       Data    :        char_array;
       Length  :        unsigned)
      with
        Global => null,
        Import        => True,
        Convention    => C,
        External_Name => "tcpWriteTxBuffer",
        Post => Model(Sock) = Model(Sock)'Old;

   procedure Tcp_Delete_Control_Block
      (Sock : Not_Null_Socket)
      with
        Import        => True,
        Convention    => C,
        External_Name => "tcpDeleteControlBlock",
        Global        => null,
        Post => -- Change the Post condition to something more true
            Model (Sock) = Model (Sock)'Old;

   procedure Tcp_Send_Segment
      (Sock         : in out Not_Null_Socket;
       Flags        :        uint8;
       Seq_Num      :        unsigned;
       Ack_Num      :        unsigned;
       Length       :        unsigned_long;
       Add_To_Queue :        Bool;
       Error        :    out Error_T)
      with
        Depends =>
            (Sock  =>+ (Flags, Seq_Num, Ack_Num, Length, Add_To_Queue),
             Error =>  (Sock, Flags, Seq_Num, Ack_Num, Length, Add_To_Queue)),
        Post =>
            (if Error = NO_ERROR then
               Model (Sock) = Model(Sock)'Old
             else
               -- If the send of the segment fail, we don't know anything
               -- about the TCP state of the Socket. But we know that our
               -- Socket still have the same type (Stream)
               Sock.S_Type = SOCKET_TYPE_STREAM);

   procedure Tcp_Update_Events
      (Sock : Not_Null_Socket)
      with
         Import => True,
         Convention => C,
         External_Name => "tcpUpdateEvents",
         Global => null,
         Post => Model(Sock) = Model(Sock)'Old;

   procedure Tcp_Nagle_Algo
      (Sock  : in out Not_Null_Socket;
       Flags : in     unsigned;
       Error :    out Error_T)
      with
         Global => null,
         Post => Model(Sock) = Model(Sock)'Old;

end Tcp_Misc_Binding;
