------------------------------------------------------------------------------
--                                                                          --
--                     Copyright (C) 2015-2016, AdaCore                     --
--                                                                          --
--  Redistribution and use in source and binary forms, with or without      --
--  modification, are permitted provided that the following conditions are  --
--  met:                                                                    --
--     1. Redistributions of source code must retain the above copyright    --
--        notice, this list of conditions and the following disclaimer.     --
--     2. Redistributions in binary form must reproduce the above copyright --
--        notice, this list of conditions and the following disclaimer in   --
--        the documentation and/or other materials provided with the        --
--        distribution.                                                     --
--     3. Neither the name of the copyright holder nor the names of its     --
--        contributors may be used to endorse or promote products derived   --
--        from this software without specific prior written permission.     --
--                                                                          --
--   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS    --
--   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT      --
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR  --
--   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   --
--   HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, --
--   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT       --
--   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,  --
--   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY  --
--   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT    --
--   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE  --
--   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.   --
--                                                                          --
------------------------------------------------------------------------------

package body Last_Chance_Handler is

   -------------------------
   -- Last_Chance_Handler --
   -------------------------

   procedure Last_Chance_Handler
     (Msg  : System.Address;
      Line : Integer)
   is
      pragma Unreferenced (Msg, Line);
      procedure Busy_loop;

      ---------------
      -- Busy_loop --
      ---------------

      procedure Busy_loop is
      begin
         for Cnt in 1 .. 10_000_000 loop
            null;
         end loop;
      end Busy_loop;
   begin

      Busy_loop;

      --  No-return procedure...
      loop
         null;
      end loop;
   end Last_Chance_Handler;

   procedure Raise_Assert_Failure
      (Msg : String)
   is
      pragma Unreferenced (Msg);
      procedure Busy_loop;

      ---------------
      -- Busy_loop --
      ---------------

      procedure Busy_loop is
      begin
         for Cnt in 1 .. 10_000_000 loop
            null;
         end loop;
      end Busy_loop;
   begin

      Busy_loop;

      --  No-return procedure...
      loop
         null;
      end loop;
   end Raise_Assert_Failure;

end Last_Chance_Handler;
