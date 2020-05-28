with Common_Type; use Common_Type;

package Net_Misc is

   type Net_Ancillary_Data is record
      Ttl         : uint8;
      Dont_Route  : Bool;
   end record;

end Net_Misc;
