module MetOfficeAPI
  
  class Util
    # Multiply by 9, then divide by 5, then add 32
    def self.celcius_to_fahrenheit temp_c
      (((temp_c.to_i * 9.0) / 5.0) + 32.0).round
    end
    
    def self.return_temp_or_convert temp_degrees, unit
      if unit === 'celcius'
        return temp_degrees
      else
        return celcius_to_fahrenheit(temp_degrees).to_s
      end
    end
    
  end
  
end