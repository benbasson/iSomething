module MetOfficeAPI
    
  class ForecastDay
  
    attr_accessor :date_string, :date_formatted_short, :date_formatted_long, :forecast_hours
    
    def initialize (weather_json, weather_units, three_hourly_period)     
      # Rep is an array of weather reports - for a day, we expect exactly two items
      raise ArgumentError, "Expected exactly 2 items in Rep, found #{weather_json['Rep'].length}" unless weather_json['Rep'].length === 2
      
      # If the above test is satisfied, then continue the parse
      day_forecast = weather_json['Rep'].first
      night_forecast = weather_json['Rep'].last
  
      # Belt and braces check
      raise ArgumentError, "Expected first element in Rep to be the 'Day' map, found '#{day_forecast['$']}'" unless (day_forecast['$'] === 'Day')
      raise ArgumentError, "Expected last element in Rep to be the 'Night' map, found '#{day_forecast['$']}'" unless (night_forecast['$'] === 'Night')
  
      # Parse date
      @date_string = weather_json['value']
      parsed_time = Time.parse(@date_string)
      @date_formatted_short = parsed_time.strftime('%a') + ' ' + parsed_time.day.to_i.ordinalize
      @date_formatted_long = parsed_time.strftime('%A') + ' ' + parsed_time.day.to_i.ordinalize + ' ' + parsed_time.strftime('%B')
  
      # Parse forecast
      @day_weather_code = day_forecast['W'].to_i
      @night_weather_code = night_forecast['W'].to_i
      
      # Parse temperatures
      @feels_like_max_temp = day_forecast['FDm']
      @max_temp = day_forecast['Dm']
      @feels_like_min_temp = night_forecast['FNm']
      @min_temp = night_forecast['Nm']
      
      # Parse units
      @feels_like_max_temp_units = weather_units['FDm']
      @max_temp_units = weather_units['Dm']
      @feels_like_min_temp_units = weather_units['FNm']
      @min_temp_units = weather_units['Nm']
      
      raise ArgumentError, "Expected temperatures in degrees celcius, with unit 'C', was provided with '#{@feels_like_max_temp_units}'" unless @feels_like_max_temp_units === MetOfficeAPI::TEMPERATURE_UNITS[MetOfficeAPI::CELCIUS]
      raise ArgumentError, "Expected temperatures in degrees celcius, with unit 'C', was provided with '#{@max_temp_units}'" unless @max_temp_units === MetOfficeAPI::TEMPERATURE_UNITS[MetOfficeAPI::CELCIUS]
      raise ArgumentError, "Expected temperatures in degrees celcius, with unit 'C', was provided with '#{@feels_like_min_temp_units}'" unless @feels_like_min_temp_units === MetOfficeAPI::TEMPERATURE_UNITS[MetOfficeAPI::CELCIUS]
      raise ArgumentError, "Expected temperatures in degrees celcius, with unit 'C', was provided with '#{@min_temp_units}'" unless @min_temp_units === MetOfficeAPI::TEMPERATURE_UNITS[MetOfficeAPI::CELCIUS]
      
      @forecast_hours = []
      three_hourly_period.each do |period_3hr|
        @forecast_hours << MetOfficeAPI::ForecastHour.new(
          period_3hr['$'],
          period_3hr['W'].to_i,
          period_3hr['T'],
          period_3hr['F'],
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