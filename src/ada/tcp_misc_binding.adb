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

with Net;               use Net;
with Os;                use Os;
with Os_Types;          use Os_Types;
with System;            use System;
with Tcp_Fsm_Binding;   use Tcp_Fsm_Binding;

package body Tcp_Misc_Binding with
   SPARK_Mode
is

   procedure Tcp_Change_State
      (Sock      : in out Not_Null_Socket;
       New_State : in     Tcp_State)
   is
   begin
      --  Enter CLOSED State?
      if New_State = TCP_STATE_CLOSED then
         --  Check previous state
         if Sock.State = TCP_STATE_LAST_ACK
           or else Sock.State = TCP_STATE_TIME_WAIT
         then
            --  The connection has been closed properly
            Sock.closed_Flag := True;
         else
            --  the connection has been reset by the peer
            Sock.reset_Flag := True;
         end if;
      end if;

      --  Enter the desired state
      Sock.State := New_State;
      --  Update TCP related events
      Tcp_Update_Events (Sock);
   end Tcp_Change_State;

   procedure Tcp_Wait_For_Events
      (Sock       : in out Not_Null_Socket;
       Event_Mask : in     Socket_Event;
       Timeout    : in     Systime;
       Event      :    out Socket_Event)
   with SPARK_Mode => Off
   is
   begin
      --  Only one of the events listed here may complete the wait
      Sock.S_Event_Mask := Event_Mask;
      --  Update TCP related events
      Tcp_Update_Events (Sock);

      --  No event is signaled?
      if Sock.S_Event_Flags = 0 then
         Os_Reset_Event (Sock.S_Event);

         --  Release exclusive access
         Os_Release_Mutex (Net_Mutex);
         --  Wait until an event is triggered
         Os_Wait_For_Event (Sock.S_Event, Timeout);
         --  Get exclusive Access
         Os_Acquire_Mutex (Net_Mutex);
      end if;

      --  Return the list of TCP events that satisfied the wait
      Event := Sock.S_Event_Flags;
   end Tcp_Wait_For_Events;

   procedure Tcp_Send_Segment
      (Sock         : in out Not_Null_Socket;
       Flags        :        uint8;
       Seq_Num      :        unsigned;
       Ack_Num      :        unsigned;
       Length       :        unsigned_long;
       Add_To_Queue :        Bool;
       Error        :    out Error_T)
   with SPARK_Mode => Off
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
         Error_T'Enum_Val (tcpSendSegment
            (Sock, Flags, Seq_Num, Ack_Num, Length, Add_To_Queue));
   end Tcp_Send_Segment;

   procedure Tcp_Nagle_Algo
      (Sock  : in out Not_Null_Socket;
       Flags : in     unsigned;
       Error :    out Error_T)
   with SPARK_Mode => Off
   is
      function tcpNagleAlgo
         (Sock  : Socket;
          Flags : unsigned) return unsigned
         with
            Import => True,
            Convention => C,
            External_Name => "tcpNagleAlgo";
   begin
      Error :=
         Error_T'Enum_Val (tcpNagleAlgo (Sock, Flags));
   end Tcp_Nagle_Algo;

   procedure Tcp_Update_Events
      (Sock : Not_Null_Socket)
   is begin
      --  Clear event flags
      Sock.S_Event_Flags := 0;

      --  Check current TCP state
      case Sock.State is
         when TCP_STATE_ESTABLISHED
            | TCP_STATE_FIN_WAIT_1 =>
            Sock.S_Event_Flags := Sock.S_Event_Flags or SOCKET_EVENT_CONNECTED;
         when TCP_STATE_FIN_WAIT_2 =>
            Sock.S_Event_Flags := Sock.S_Event_Flags
                                  or SOCKET_EVENT_CONNECTED
                                  or SOCKET_EVENT_TX_SHUTDOWN;
         when TCP_STATE_CLOSE_WAIT
            | TCP_STATE_LAST_ACK
            | TCP_STATE_CLOSING =>
            Sock.S_Event_Flags := Sock.S_Event_Flags
                                  or SOCKET_EVENT_CONNECTED
                                  or SOCKET_EVENT_RX_SHUTDOWN;
         when TCP_STATE_TIME_WAIT
            | TCP_STATE_CLOSED =>
            Sock.S_Event_Flags := Sock.S_Event_Flags
                                  or SOCKET_EVENT_CLOSED
                                  or SOCKET_EVENT_TX_SHUTDOWN
                                  or SOCKET_EVENT_RX_SHUTDOWN;
         when others => null;
      end case;

      --  Handle TX specific events
      if Sock.State in TCP_STATE_SYN_SENT
                       | TCP_STATE_SYN_RECEIVED
      then
         Sock.S_Event_Flags := Sock.S_Event_Flags
                               or SOCKET_EVENT_TX_DONE
                               or SOCKET_EVENT_TX_ACKED;
      elsif Sock.State in TCP_STATE_ESTABLISHED
                        | TCP_STATE_CLOSE_WAIT
      then
         --  Check whether the send buffer is full or not
         if unsigned (Sock.sndUser) + Sock.sndNxt -
           Sock.sndUna < unsigned (Sock.txBufferSize)
         then
            Sock.S_Event_Flags := Sock.S_Event_Flags or SOCKET_EVENT_TX_READY;
         end if;

         --  Check whether all the data in the send buffer has been transmitted
         if Sock.sndUser = 0 then
            --  All the pending data has been sent out
            Sock.S_Event_Flags := Sock.S_Event_Flags or SOCKET_EVENT_TX_DONE;

            --  Check whether an acknowledgment has been received
            --  @TODO check the correcness of this condition
            if ((Sock.sndUna - Sock.sndNxt) and 16#8000_0000#) = 0 then
               Sock.S_Event_Flags := Sock.S_Event_Flags or
                 SOCKET_EVENT_TX_ACKED;
            end if;
         end if;
      elsif Sock.State /= TCP_STATE_LISTEN then
         Sock.S_Event_Flags := Sock.S_Event_Flags
                               or SOCKET_EVENT_TX_READY
                               or SOCKET_EVENT_TX_DONE
                               or SOCKET_EVENT_TX_ACKED;
      end if;

      --  Handle RX specific events
      if Sock.State in TCP_STATE_ESTABLISHED
                     | TCP_STATE_FIN_WAIT_1
                     | TCP_STATE_FIN_WAIT_2
      then
         --  Data is available for reading?
         if Sock.rcvUser > 0 then
            Sock.S_Event_Flags := Sock.S_Event_Flags or SOCKET_EVENT_RX_READY;
         end if;
      elsif Sock.State = TCP_STATE_LISTEN then
         --  If the socket is currently in the listen state, it will be marked
         --  as readable if an incoming connection request has been received
         if Sock.synQueue /= null then
            Sock.S_Event_Flags := Sock.S_Event_Flags or SOCKET_EVENT_RX_READY;
         end if;
      elsif Sock.State /= TCP_STATE_SYN_SENT and then
            Sock.State /= TCP_STATE_SYN_RECEIVED
      then
         --  Readability can also indicate that a request to close
         --  the socket has been received from the peer
         Sock.S_Event_Flags := Sock.S_Event_Flags or SOCKET_EVENT_RX_READY;
      end if;

      --  Check whether the socket is bound to a particular network interface
      pragma Warnings (Off, "statement has no effect",
                       Reason => "This is inherited from the C code."
                       & "A special event can be raised if the Network "
                       & "interface is disconnected. It would be necessary "
                       & "to go deeper into the C to SPARK translation to "
                       & "handle this part in SPARK. In particular, the "
                       & "network interface will need further definition. "
                       & "This is not necessary for the SPARK proof because "
                       & "the SPARK code never needs to check if the network "
                       & "interface is connected or disconnected.");
      if Sock.S_Net_Interface /= System.Null_Address then
         --  Handle link up and link down events
         --  @TODO voir comment faire ici même si non nécessaire dans les cas
         --  que j'ai
         null;
      end if;
      pragma Warnings (On, "statement has no effect");

      --  Mask unused events
      Sock.S_Event_Flags := Sock.S_Event_Flags and Sock.S_Event_Mask;

      --  Any event to signal?
      if Sock.S_Event_Flags /= 0 then
         --  Unblock I/O operations currently in waiting state
         Os_Set_Event (Sock.S_Event);

         --  Set user event to signaled state if necessary
         if Sock.S_User_Event /= null then
            Os_Set_Event (Sock.S_User_Event);
         end if;
      end if;
   end Tcp_Update_Events;

   procedure Tcp_Wait_For_Events_Proof
      (Sock       : in out Not_Null_Socket;
       Event_Mask : in     Socket_Event;
       Event      :    out Socket_Event)
   is
   begin
      --  Only one of the events listed here may complete the wait
      Sock.S_Event_Mask := Event_Mask;

      --  Update TCP related events
      Tcp_Update_Events (Sock);

      --  An event signaled?
      if Sock.S_Event_Flags /= 0 then
         Event := Sock.S_Event_Flags;
         return;
      else
         for I in 1 .. 3 loop
            --  Simulate the reception of a message
            Tcp_Process_One_Segment (Sock);
            --  Update TCP related events
            Tcp_Update_Events (Sock);
            --  An event signaled?
            if Sock.S_Event_Flags /= 0 then
               Event := Sock.S_Event_Flags;
               return;
            end if;
         end loop;
      end if;

      Event := SOCKET_EVENT_TIMEOUT;
   end Tcp_Wait_For_Events_Proof;

end Tcp_Misc_Binding;
