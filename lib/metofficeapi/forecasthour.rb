require 'active_support/all'

module MetOfficeAPI

  class ForecastHour

    attr_accessor :time_str

    def initialize hour, weather_code, temp, feels_like_temp
      @time_str = "#{hour.to_s.rjust(2, "0")}:00"
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