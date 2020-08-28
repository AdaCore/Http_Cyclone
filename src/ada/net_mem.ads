with Interfaces.C; use Interfaces.C;
with System;

package Net_Mem is

   -- Size of the buffers
#if NET_MEM_POOL_BUFFER_SIZE'Defined then
   NET_MEM_POOL_BUFFER_SIZE : constant Positive := $NET_MEM_POOL_BUFFER_SIZE;
#else
   NET_MEM_POOL_BUFFER_SIZE : constant Positive := 1536;
#end if;

   type Chunk_Desc is record
      address : System.Address;
      length  : unsigned_short;
      size    : unsigned_short;
   end record
     with
      Convention => C, Object_Size => 32 + System.Word_Size;
end Net_Mem;
