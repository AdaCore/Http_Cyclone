with Interfaces.C; use Interfaces.C;

package Net is

   type Net_Interface is 
      record
         Index: unsigned;
      end record
     with Convention => C;

end Net;
