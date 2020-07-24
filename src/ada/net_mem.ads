with Interfaces.C; use Interfaces.C;
with System;

package Net_Mem is

   type Chunk_Desc is record
      address : System.Address;
      length  : unsigned_short;
      size    : unsigned_short;
   end record
     with
      Convention => C, Object_Size => 32 + System.Word_Size;
end Net_Mem;
