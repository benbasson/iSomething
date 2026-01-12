require 'andand'
require 'active_support/core_ext/time'
require 'thread'

module MetOfficeAPI

  FORECAST_DAILY_URL = 'https://data.hub.api.metoffice.gov.uk/sitespecific/v0/point/daily'
  FORECAST_3_HOUR_URL = 'https://data.hub.api.metoffice.gov.uk/sitespecific/v0/point/three-hourly'

  class Forecaster

    attr_accessor :location_cache

    def initialize api_key
      @api_key = api_key
      @location_cache = MetOfficeAPI::LocationCache.new
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
      location = @location_cache.get_location location_id
      forecast_days = []

      begin
        # Fetch data
        daily_json = HTTParty.get(FORECAST_DAILY_URL, :query => {"latitude": location.latitude, "longitude": location.longitude}, :headers => {"apikey": @api_key})
        three_hourly_json = HTTParty.get(FORECAST_3_HOUR_URL, :query => {"latitude": location.latitude, "longitude": location.longitude}, :headers => {"apikey": @api_key})

        # Now parse each day into an object that we can work with easier in the HAML
        daily_json['features'][0]['properties']['timeSeries'].each do |day|

          daily_date = Time.parse(day['time']).to_date

          # skip previous day if present
          next if (daily_date < Date.today || daily_date > Date.today + 5)

          # now find the three hourly forecasts for the day we care about
          three_hourly_forecasts = three_hourly_json['features'][0]['properties']['timeSeries']
                                     .select{|period_3hr| daily_date === Time.parse(period_3hr['time']).to_date}

          # If the day doesn't have any 3 hourly forecasts then just skip showing it
          next if (three_hourly_forecasts.nil? || three_hourly_forecasts.empty?)
          forecast_days << MetOfficeAPI::ForecastDay.new(day, three_hourly_forecasts)
        end

      rescue

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

