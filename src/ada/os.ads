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

with Common_Type;  use Common_Type;
with Os_Types;     use Os_Types;
with Socket_Types; use Socket_Types;
with Tcp_Type;     use Tcp_Type;

package Os with
   SPARK_Mode
is

   --  Mutex management
   procedure Os_Acquire_Mutex (Mutex : Os_Mutex);

   procedure Os_Release_Mutex (Mutex : Os_Mutex);

   function Os_Get_System_Time return Systime
     with
      Import        => True,
      Convention    => C,
      External_Name => "osGetSystemTime",
      Global        => null;

   procedure Os_Reset_Event (Event : Os_Event);

   procedure Os_Set_Event (Event : Os_Event);

   procedure Os_Set_Event (Event : access Os_Event);

   procedure Os_Wait_For_Event
      (Event   : Os_Event;
       Timeout : Systime);

   --  We need to use a procedure that takes the socket as an argument
   --  and modify it as wanted for the verification.
   --  Indeed the data process is done in another file, and only an event
   --  linked the raw data and the highest part of the protocol.
   --  Doing it so allow to give a contract at the end of the procedure
   --  that resume what have been done on the raw data process side.
   procedure Os_Wait_For_Event
      (Sock : in out Not_Null_Socket)
   with
      Global => null,
      Pre => Sock.S_Type = SOCKET_TYPE_STREAM,
      Contract_Cases =>
         (Sock.State = TCP_STATE_LISTEN =>
               Model (Sock) = Model (Sock)'Old and then
               Tcp_Syn_Queue_Item_Model (Sock.synQueue),
         others => Model (Sock) = Model (Sock)'Old);

end Os;
