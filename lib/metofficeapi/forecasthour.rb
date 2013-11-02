require 'active_support/all'

module MetOfficeAPI
  
  class ForecastHour
    
    attr_accessor :time_str
    
    def initialize mins_since_midnight, weather_code, temp, feels_like_temp
      @time_str = (Time.now.beginning_of_day + 60 * mins_since_midnight.to_i).strftime("%H:%M")
      @weather_code = weather_code
      @temp = temp
      @feels_like_temp = feels_like_temp
    end
    
    def weather_text
      WEATHER_TYPES.fetch(@weather_code)
    end

    def weather_image
      WEATHER_IMAGES.fetch(@weather_code)
    end
    
    def temp unit = nil
      unit ||= MetOfficeAPI::CELCIUS
      MetOfficeAPI::Util.return_temp_or_convert @temp, unit
    end
    
    def feels_like_temp unit = nil
      unit ||= MetOfficeAPI::CELCIUS
      MetOfficeAPI::Util.return_temp_or_convert @feels_like_temp, unit
    end
    
  end
  
end  