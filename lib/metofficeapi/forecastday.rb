module MetOfficeAPI

  class ForecastDay

    attr_accessor :date_string, :date_formatted_short, :date_formatted_long, :forecast_hours

    def initialize (day_json, period_3hr_list)

      # Parse date
      @date_string = day_json['time']
      parsed_time = Time.parse(@date_string)
      @date_formatted_short = parsed_time.strftime('%a') + ' ' + parsed_time.day.to_i.ordinalize
      @date_formatted_long = parsed_time.strftime('%A') + ' ' + parsed_time.day.to_i.ordinalize + ' ' + parsed_time.strftime('%B')

      # Parse forecast for day/night
      @day_weather_code = day_json['daySignificantWeatherCode']
      @night_weather_code = day_json['nightSignificantWeatherCode']

      # Parse temperatures for day/night
      @feels_like_max_temp = day_json['dayMaxFeelsLikeTemp'].to_i
      @max_temp = day_json['dayUpperBoundMaxTemp'].to_i
      @feels_like_min_temp = day_json['nightMinFeelsLikeTemp'].to_i
      @min_temp = day_json['nightLowerBoundMinTemp'].to_i

      # Now process the 3 hourly blocks
      @forecast_hours = []
      period_3hr_list.each do |period_3hr|
        average_temp = (period_3hr['maxScreenAirTemp'] + period_3hr['minScreenAirTemp']) / 2
        @forecast_hours << MetOfficeAPI::ForecastHour.new(
          Time.parse(period_3hr['time']).hour,
          period_3hr['significantWeatherCode'],
          average_temp.to_i,
          period_3hr['feelsLikeTemp'].to_i,
        )
      end

    end

    def day_weather_text
      MetOfficeAPI::WEATHER_TYPES.fetch(@day_weather_code)
    end

    def night_weather_text
      MetOfficeAPI::WEATHER_TYPES.fetch(@night_weather_code)
    end

    def day_weather_image
      MetOfficeAPI::WEATHER_IMAGES.fetch(@day_weather_code)
    end

    def night_weather_image
      MetOfficeAPI::WEATHER_IMAGES.fetch(@night_weather_code)
    end

    def feels_like_max_temp unit = nil
      unit ||= MetOfficeAPI::CELCIUS
      MetOfficeAPI::Util.return_temp_or_convert @feels_like_max_temp, unit
    end

    def max_temp unit = nil
      unit ||= MetOfficeAPI::CELCIUS
      MetOfficeAPI::Util.return_temp_or_convert @max_temp, unit
    end

    def feels_like_min_temp unit = nil
      unit ||= MetOfficeAPI::CELCIUS
      MetOfficeAPI::Util.return_temp_or_convert @feels_like_min_temp, unit
    end

    def min_temp unit = nil
      unit ||= MetOfficeAPI::CELCIUS
      MetOfficeAPI::Util.return_temp_or_convert @min_temp, unit
    end

    def temp_units unit = nil
      unit ||= MetOfficeAPI::CELCIUS
      return MetOfficeAPI::TEMPERATURE_UNITS[unit]
    end

  end
end