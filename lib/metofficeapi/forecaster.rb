require 'andand'
require 'active_support/core_ext/time'
require 'thread'

module MetOfficeAPI
  
  class Forecaster
    
    attr_accessor :location_cache
    
    def initialize api_key
      @api_key = api_key
      @location_cache = MetOfficeAPI::LocationCache.new api_key
      @forecast_cache = Hash.new
      
      # Worker thread to refresh the cache
      Thread.new do
        while true do
          # Cycle through each location and see if it needs to be updated;
          # in any case we're doing nothing with the result
          @forecast_cache.each do |k,v|
            get_forecast k
          end
          sleep 60
        end
      end
      
    end
    
    def is_location_valid location_id
      @location_cache.has_location location_id
    end
    
    def get_forecast location_id
      # Use an existing cached value if available and if not timed out 
      forecast = @forecast_cache[location_id]
      return forecast unless forecast.nil? or Time.now > forecast.created_time.end_of_hour 
      
      puts "#{Time.now.to_formatted_s :db} :: Forecast for location #{location_id} has expired, fetching new data." unless forecast.nil? 

      weather_units = Hash.new
      forecast_days = []
      
      mdp = MetofficeDatapoint.new(api_key: @api_key)
      
      begin
        # Call out to the MDP API
        daily_json = mdp.forecasts location_id, options = {res: 'daily'}
        three_hourly_json = mdp.forecasts location_id, options = {res: '3hourly'}
                
        # Parse the property units
        if not daily_json.nil? and not daily_json['SiteRep'].andand['Wx'].andand['Param'].nil?
          daily_json['SiteRep']['Wx']['Param'].each do |param|
            name = param['name']
            weather_units[name] = param['units']
          end
        end
        
      rescue Oj::ParseError, MetofficeDatapoint::Errors::NotFoundError => ex
        backtrace = ex.backtrace.join("\n")
        puts "#{Time.now.to_formatted_s :db} :: Failed to parse weather data from Met Office DataPoint :: #{ex.message}\n#{backtrace}"
      end
    
      # Now parse each day into an object that we can work with easier in the HAML    
      # Hilarious fun with andand, but saves a trillion nil checks and copes with the
      # possibility of malformed JSON coming back fairly gracefully... none of this stuff
      # should be nil
      if not daily_json.nil? and 
        not daily_json['SiteRep'].andand['DV'].andand['Location'].andand['Period'].nil? and 
        not three_hourly_json.nil? and 
        not three_hourly_json['SiteRep'].andand['DV'].andand['Location'].andand['Period'].nil?
              
        daily_json['SiteRep']['DV']['Location']['Period'].each do |period|
          three_hourly_period = nil
          if not three_hourly_json.nil?
            three_hourly_json['SiteRep']['DV']['Location']['Period'].each do |period_3hr|
              if period_3hr['value'] === period['value']
                three_hourly_period = period_3hr['Rep']
              end
            end
          end
          
          raise IndexError, "No 3-hourly forecast found for date #{period['value']}" unless not three_hourly_period.nil?
          forecast_days << MetOfficeAPI::ForecastDay.new(period, weather_units, three_hourly_period)
        end
        
      end
      
      # If we have a cached forecast already and the new one has failed, just use the cached version
      return forecast if forecast_days.length == 0 and not forecast.nil?
      
      # Otherwise, we're building up a new forecast object
      location = @location_cache.get_location location_id
      forecast = MetOfficeAPI::Forecast.new location, forecast_days
      
      # Cache and return - only cache if we actually have any forecast data
      @forecast_cache[location_id] = forecast unless forecast_days.length == 0
      return forecast

    end
    
  end
  
end
  
