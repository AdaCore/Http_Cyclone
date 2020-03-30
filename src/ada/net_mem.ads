with System;
with Interfaces.C; use Interfaces.C;

package Net_Mem is

   type Chunk_Desc is 
      record
         address: System.Address;
         length: unsigned_short;
         size: unsigned_short;
      end record
     with Convention => C;

end Net_Mem;
