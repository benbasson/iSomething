module MetOfficeAPI
  
  class Forecast
    
    attr_accessor :forecast_days, :created_time
    
    def initialize location, forecast_days
      # Belt and braces argument checks
      raise ArgumentError, "Must provide a MetOfficeAPI::Location" unless not location.nil? 
      raise ArgumentError, "Must provide a MetOfficeAPI::Location" unless location.is_a? MetOfficeAPI::Location
      raise ArgumentError, "Must provide an array of MetOfficeAPI::ForecastDay elements" unless forecast_days.all? {|x| x.is_a? MetOfficeAPI::ForecastDay}
      
      @location = location
      @forecast_days = forecast_days
      @created_time = Time.now
    end 
    
    def location_name 
      @location.name
    end
    
    def location_id
      @location.id
    end
    
    def get_forecast_day date_string
      @forecast_days.each do |forecast_day|
        if forecast_day.date_string === date_string
          return forecast_day
        end
      end
      # Reached end of loop and didn't find anything relevant
      raise IndexError, "ForecastDay with date '#{date_string}' not found in Forecast"
    end

  end
  
end