with System;

package body Tcp_Misc_Binding with
   SPARK_Mode => Off
is

   procedure Tcp_Change_State
      (Sock      : in out Not_Null_Socket;
       New_State : in     Tcp_State)
   is
      procedure tcpUpdateEvents (Sock : Socket) with
         Import        => True,
         Convention    => C,
         External_Name => "tcpUpdateEvents";
   begin
      -- Enter CLOSED State?
      if New_State = TCP_STATE_CLOSED then
         -- Check previous state
         if Sock.State = TCP_STATE_LAST_ACK
           or else Sock.State = TCP_STATE_TIME_WAIT
         then
            -- The connection has been closed properly
            Sock.closed_Flag := True;
         else
            -- the connection has been reset by the peer
            Sock.reset_Flag := True;
         end if;
      end if;

      -- Enter the desired state
      Sock.State := New_State;
      -- Update TCP related events
      tcpUpdateEvents (Sock);
   end Tcp_Change_State;

   procedure Tcp_Wait_For_Events
      (Sock       : in out Not_Null_Socket;
       Event_Mask : in     Socket_Event;
       Timeout    : in     Systime;
       Event      :    out Socket_Event)
   is
      function tcpWaitForEvents
        (Sock      : Socket;
         eventMask : unsigned;
         timeout   : Systime)
         return unsigned with
         Import        => True,
         Convention    => C,
         External_Name => "tcpWaitForEvents";
   begin
      Event := Socket_Event(tcpWaitForEvents (Sock, unsigned(Event_Mask), Timeout));
   end Tcp_Wait_For_Events;

   procedure Tcp_Send_Segment
      (Sock         : in out Not_Null_Socket;
       Flags        :        uint8;
       Seq_Num      :        unsigned;
       Ack_Num      :        unsigned;
       Length       :        unsigned_long;
       Add_To_Queue :        Bool;
       Error        :    out Error_T)
   is
      function tcpSendSegment
         (Sock         : Socket;
          Flags        : uint8;
          Seq_Num      : unsigned;
          Ack_Num      : unsigned;
          Length       : unsigned_long;
          Add_To_Queue : Bool) return unsigned
         with
            Import => True,
            Convention => C,
            External_Name => "tcpSendSegment";
   begin
      Error :=
         Error_T'Enum_Val(tcpSendSegment
            (Sock, Flags, Seq_Num, Ack_Num, Length, Add_To_Queue));
   end Tcp_Send_Segment;

end Tcp_Misc_Binding;
