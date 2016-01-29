require_relative '../spec_helper'

describe "MetOfficeAPI" do
  
  before :all do
    # Read Met Office API from environment variable or local file
    @api_key = ENV['METOFFICE_API_KEY'] || File.read(File.expand_path(File.dirname(__FILE__) + '/../../.metoffice-api-key'))
    
    # Sample locations file
    @stub_sitelist = File.read(File.expand_path(File.dirname(__FILE__) + '/testfiles/sitelist.json'))
    @stub_forecast_daily = File.read(File.expand_path(File.dirname(__FILE__) + '/testfiles/forecast-daily.json'))
    @stub_forecast_3hourly = File.read(File.expand_path(File.dirname(__FILE__) + '/testfiles/forecast-3hourly.json'))
    @stub_forecast_nodata = File.read(File.expand_path(File.dirname(__FILE__) + '/testfiles/forecast-nodata.json'))
  end
  
  before :each do
    # Stub sitelist request to our local file
    stub_request(:get, "http://datapoint.metoffice.gov.uk/public/data/val/wxfcs/all/json/sitelist?key=#{@api_key}")
      .to_return(:status => 200, :headers => {'Content-Type'=>'application/json'}, :body => @stub_sitelist)
      
    stub_request(:get, "http://datapoint.metoffice.gov.uk/public/data/val/wxfcs/all/json/3072?key=#{@api_key}&res=daily")
      .to_return(:status => 200, :headers => {'Content-Type'=>'application/json'}, :body => @stub_forecast_daily)
      
    stub_request(:get, "http://datapoint.metoffice.gov.uk/public/data/val/wxfcs/all/json/3072?key=#{@api_key}&res=3hourly")
      .to_return(:status => 200, :headers => {'Content-Type'=>'application/json'}, :body => @stub_forecast_3hourly)
  end
  
  describe "Location" do
    
    before :all do
      @test_id = 1
      @test_name = 'Place'
      @test_lat = '0.1234'
      @test_lon = '0.2345'
      @location = MetOfficeAPI::Location.new @test_id, @test_name, @test_lat, @test_lon
    end
    
    it "should have the right id" do
      @location.id.should eq @test_id
    end 
    
    it "should have the right name" do
      @location.name.should eq @test_name
    end
    
    it "should have the right latitude" do
      @location.latitude.should eq @test_lat
    end
    
    it "should have the right longitude" do
      @location.longitude.should eq @test_lon
    end
    
  end #Location
  
  describe "LocationCache" do
    
    before :each do 
      @cache = MetOfficeAPI::LocationCache.new @api_key
    end
    
    it "should automatically retrieve lots of values" do
      @cache.all_locations.size.should eq 5964
    end
    
    it "should contain only instances of MetOfficeAPI::Location" do
      @cache.all_locations.each do |k,v|
        v.should be_a MetOfficeAPI::Location
      end
    end
    
    it "should have hash keys that match the location ids" do
      @cache.all_locations.each do |k,v|
        k.should eq v.id
      end
    end
    
    it "should not update when called immediately after construction" do
      t1 = @cache.last_location_update
      @cache.all_locations
      t2 = @cache.last_location_update
      t1.should eq t2
    end
    
    it "should act as a cache and serve out the same object again" do
      k,v = @cache.all_locations.first
      location = @cache.get_location k
      location2 = @cache.get_location k
      v.should equal location
      location.should equal location2
    end
    
    it "should raise an ArgumentError if provided a Nil location_id" do
      expect {@cache.get_location}.to raise_error(ArgumentError)
    end
    
    it "should raise an ArgumentError if provided an integer location_id" do
      k,v = @cache.all_locations.first
      expect {@cache.get_location(k.to_i)}.to raise_error(ArgumentError)
    end
    
    it "should raise a KeyError if provided an invalid location_id" do
      expect {@cache.get_location('not-there')}.to raise_error(KeyError)
    end
    
    it "should cope gracefully when the sitelist isn't available" do
      stub_request(:get, "http://datapoint.metoffice.gov.uk/public/data/val/wxfcs/all/json/sitelist?key=#{@api_key}")
        .to_return(status: 404, headers: {'Content-Type'=>'text/html'}, body: '')
      $stdout.stub(:puts) # Suppress logging to keep rspec output looking tidy
      cache = MetOfficeAPI::LocationCache.new @api_key
      cache.all_locations.size.should eq 0
    end
    
    it "should cope gracefully when the sitelist is malformed" do
      stub_request(:get, "http://datapoint.metoffice.gov.uk/public/data/val/wxfcs/all/json/sitelist?key=#{@api_key}")
        .to_return(status: 200, headers: {'Content-Type'=>'application/json'}, body: 'not-a-json-response')
      $stdout.stub(:puts) # Suppress logging to keep rspec output looking tidy
      cache = MetOfficeAPI::LocationCache.new @api_key
      cache.all_locations.size.should eq 0
    end
    
  end #LocationCache
  
  describe "ForecastHour" do
    
    before :all do
      @weather_code = '1'
      @temp = '10'
      @temp_f = '50'
      @feels_like_temp = '9'
      @feels_like_temp_f = '48'
      @forecast_hour = MetOfficeAPI::ForecastHour.new '0', @weather_code, @temp, @feels_like_temp
    end
    
    it "should accurately convert minutes past midnight into a time string" do
      fh = MetOfficeAPI::ForecastHour.new '0', @weather_code, @temp, @feels_like_temp
      fh.time_str.should eq '00:00'
      
      fh = MetOfficeAPI::ForecastHour.new '720', @weather_code, @temp, @feels_like_temp
      fh.time_str.should eq '12:00'
      
      fh = MetOfficeAPI::ForecastHour.new '1051', @weather_code, @temp, @feels_like_temp
      fh.time_str.should eq '17:31'
    end
    
    it "should have the correct temp with no units specified" do
      @forecast_hour.temp.should eq @temp
    end
    
    it "should have the correct 'feels like' temp with no units specified" do
      @forecast_hour.feels_like_temp.should eq @feels_like_temp
    end
    
    it "should have the correct temp" do
      @forecast_hour.temp(MetOfficeAPI::CELCIUS).should eq @temp
    end
    
    it "should have the correct 'feels like' temp" do
      @forecast_hour.feels_like_temp(MetOfficeAPI::CELCIUS).should eq @feels_like_temp
    end
    
    it "should have the correct temp" do
      @forecast_hour.temp(MetOfficeAPI::FAHRENHEIT).should eq @temp_f
    end
    
    it "should have the correct 'feels like' temp" do
      @forecast_hour.feels_like_temp(MetOfficeAPI::FAHRENHEIT).should eq @feels_like_temp_f
    end

  end #ForecastHour

  describe "ForecastDay" do
    
    before :all do
      @date_str = '2013-11-03Z'
      @test_json = {
        'value' => @date_str,
        'Rep' => [
          {"D"=>"NW", "Gn"=>"16", "Hn"=>"80", "PPd"=>"9", "S"=>"7", "V"=>"VG", "Dm"=>"7", "FDm"=>"4", "W"=>"1", "U"=>"1", "$"=>"Day"},
          {"D"=>"WNW", "Gm"=>"13", "Hm"=>"90", "PPn"=>"44", "S"=>"2", "V"=>"VG", "Nm"=>"0", "FNm"=>"-1", "W"=>"2", "$"=>"Night"}
        ]
      }
      @test_units = {'FNm' => 'C', 'FDm' => 'C', 'Nm' => 'C', 'Dm' => 'C'}
      @three_hourly_forecast = [
        {"D"=>"WSW", "F"=>"8", "G"=>"31", "H"=>"61", "Pp"=>"15", "S"=>"18", "T"=>"11", "V"=>"GO", "W"=>"3", "U"=>"1", "$"=>"720"},
        {"D"=>"WSW", "F"=>"8", "G"=>"25", "H"=>"64", "Pp"=>"14", "S"=>"18", "T"=>"11", "V"=>"GO", "W"=>"3", "U"=>"1", "$"=>"900"},
        {"D"=>"SSW", "F"=>"7", "G"=>"16", "H"=>"70", "Pp"=>"10", "S"=>"9", "T"=>"9", "V"=>"GO", "W"=>"2", "U"=>"0", "$"=>"1080"},
        {"D"=>"ESE", "F"=>"7", "G"=>"16", "H"=>"86", "Pp"=>"96", "S"=>"7", "T"=>"9", "V"=>"MO", "W"=>"15", "U"=>"0", "$"=>"1260"},      
      ]
      @forecast_day = MetOfficeAPI::ForecastDay.new @test_json, @test_units, @three_hourly_forecast
    end
    
    it "should raise an ArgumentError on construction if more than two Rep elements are found" do
      expect {MetOfficeAPI::ForecastDay.new({'Rep' => [{},{},{}]}, @test_units, @three_hourly_forecast)}.to raise_error(ArgumentError)
    end
    
    it "should raise an ArgumentError on construction if the day and night are in the wrong order" do
      expect {MetOfficeAPI::ForecastDay.new({'Rep' => [{'$' => 'Night'},{'$' => 'Day'}]}, @test_units, @three_hourly_forecast)}.to raise_error(ArgumentError)
    end
    
    it "should have the right date" do
      @forecast_day.date_string.should eq @date_str
    end
    
    it "should have the correct 'feels like' min temp with no units specified" do
      @forecast_day.feels_like_min_temp.should eq '-1'
    end
    
    it "should have the correct 'feels like' max temp with no units specified" do
      @forecast_day.feels_like_max_temp.should eq '4'
    end
    
    it "should have the correct min temp with no units specified" do
      @forecast_day.min_temp.should eq '0'
    end
    
    it "should have the correct max temp with no units specified" do
      @forecast_day.max_temp.should eq '7'
    end
   
    it "should have the correct temperature unit with no units specified" do
      @forecast_day.temp_units.should eq 'C'
    end
    
    it "should have the correct 'feels like' min temp" do
      @forecast_day.feels_like_min_temp(MetOfficeAPI::CELCIUS).should eq '-1'
    end
    
    it "should have the correct 'feels like' max temp" do
      @forecast_day.feels_like_max_temp(MetOfficeAPI::CELCIUS).should eq '4'
    end
    
    it "should have the correct min temp" do
      @forecast_day.min_temp(MetOfficeAPI::CELCIUS).should eq '0'
    end
    
    it "should have the correct max temp" do
      @forecast_day.max_temp(MetOfficeAPI::CELCIUS).should eq '7'
    end
    
    it "should have the correct temperature unit" do
      @forecast_day.temp_units(MetOfficeAPI::CELCIUS).should eq 'C'
    end
    
    it "should have the correct 'feels like' min temp" do
      @forecast_day.feels_like_min_temp(MetOfficeAPI::FAHRENHEIT).should eq '30'
    end
    
    it "should have the correct 'feels like' max temp" do
      @forecast_day.feels_like_max_temp(MetOfficeAPI::FAHRENHEIT).should eq '39'
    end
    
    it "should have the correct min temp" do
      @forecast_day.min_temp(MetOfficeAPI::FAHRENHEIT).should eq '32'
    end
    
    it "should have the correct max temp" do
      @forecast_day.max_temp(MetOfficeAPI::FAHRENHEIT).should eq '45'
    end
   
    it "should have the correct temperature unit" do
      @forecast_day.temp_units(MetOfficeAPI::FAHRENHEIT).should eq 'F'
    end
    
  end #ForecastDay

  describe "Forecast" do
    
    before :all do
      @location_name = 'Test Location'
      @location = MetOfficeAPI::Location.new '1', @location_name, 0.0, 0.0
      @date_string = '2013-11-03Z'
      @forecast_day = MetOfficeAPI::ForecastDay.new({'value' => @date_string, 'Rep' => [{'$' => 'Day'},{'$' => 'Night'}]}, {'FDm' => 'C', 'Dm' => 'C', 'FNm' => 'C', 'Nm' => 'C'}, {})
    end
    
    it "should return the correct location name" do
      @forecast = MetOfficeAPI::Forecast.new @location, [@forecast_day]
      @forecast.location_name.should eq @location_name
    end
    
    it "should not accept a Nil location" do
      expect{MetOfficeAPI::Forecast.new nil, [@forecast_day]}.to raise_error ArgumentError
    end
    
    it "should accept an array of ForecastDay elements" do
      forecast_days = [@forecast_day, @forecast_day]
      MetOfficeAPI::Forecast.new @location, forecast_days
    end
    
    it "should not accept an array with any other object type" do
      forecast_days = [@forecast_day, nil, 123, 'String', @forecast_day]
      expect {MetOfficeAPI::Forecast.new @location, forecast_days}.to raise_error ArgumentError
    end
    
    it "should return a MetOfficeAPI::ForecastDay for a specific date string" do
      @forecast = MetOfficeAPI::Forecast.new @location, [@forecast_day]
      forecast_day = @forecast.get_forecast_day @date_string
      forecast_day.should equal @forecast_day
    end
    
    it "should raise an IndexError if the specified date string doesn't match a MetOfficeAPI::ForecastDay" do
      @forecast = MetOfficeAPI::Forecast.new @location, [@forecast_day]
      expect {@forecast.get_forecast_day '2013-11-04Z'}.to raise_error IndexError
    end
    
  end #Forecast
  
  describe "Forecaster" do
    
    before :each do
      @forecaster = MetOfficeAPI::Forecaster.new @api_key
      @location_id, dummy = '3072'
    end
    
    it "should return a MetOfficeAPI::Forecast object for a location" do
      forecast = @forecaster.get_forecast @location_id
      forecast.should be_a MetOfficeAPI::Forecast
    end
    
    it "should cache a forecast and serve out the same object again" do
      forecast = @forecaster.get_forecast @location_id
      forecast2 = @forecaster.get_forecast @location_id
      forecast.should equal forecast2
    end
    
    it "should return a new forecast when the cache has expired" do
      # Get the current date as a string
      date_str = Date.current.to_formatted_s :db
      
      # Make Time.now return a known date/time
      Time.stub(:now).and_return(Time.parse("#{date_str} 13:05"))
      
      # Get an initial forecast object to test
      forecast = @forecaster.get_forecast @location_id
      
      # Suppress logging to keep rspec output looking tidy
      $stdout.stub(:puts)
     
      # Now force the time to be when the cache should have expired
      Time.stub(:now).and_return(Time.parse("#{date_str} 14:00"))
      
      # Get another forecast and compare objects
      forecast2 = @forecaster.get_forecast @location_id
      forecast.should_not equal forecast2
    end
    
    it "should receive a boolean result when checking if a location is valid" do
      @forecaster.is_location_valid('-1').should be_falsey
      @forecaster.is_location_valid(@location_id).should be_truthy
    end
    
    it "should cope gracefully when the sitelist isn't available" do
      stub_request(:get, "http://datapoint.metoffice.gov.uk/public/data/val/wxfcs/all/json/sitelist?key=#{@api_key}")
        .to_return(:status => 404, :headers => {'Content-Type'=>'text/html'}, :body => '')
      $stdout.stub(:puts) # Suppress logging to keep rspec output looking tidy
        
      forecaster = MetOfficeAPI::Forecaster.new @api_key
      dummy = forecaster.location_cache.all_locations.first
    end
    
    it "should cope gracefully when the sitelist is malformed" do
      stub_request(:get, "http://datapoint.metoffice.gov.uk/public/data/val/wxfcs/all/json/sitelist?key=#{@api_key}")
        .to_return(:status => 200, :headers => {'Content-Type'=>'application/json'}, :body => 'not-a-json-response')
      $stdout.stub(:puts) # Suppress logging to keep rspec output looking tidy
        
      forecaster = MetOfficeAPI::Forecaster.new @api_key
      dummy = forecaster.location_cache.all_locations.first
    end
    
    it "should cope gracefully when the day forecast isn't available" do
      stub_request(:get, "http://datapoint.metoffice.gov.uk/public/data/val/wxfcs/all/json/3072?key=#{@api_key}&res=daily")
        .to_return(:status => 404, :headers => {'Content-Type'=>'text/html'}, :body => '')
      $stdout.stub(:puts) # Suppress logging to keep rspec output looking tidy
      
      forecast = @forecaster.get_forecast @location_id
    end
    
    it "should cope gracefully when the day forecast is malformed" do
      stub_request(:get, "http://datapoint.metoffice.gov.uk/public/data/val/wxfcs/all/json/3072?key=#{@api_key}&res=daily")
        .to_return(:status => 200, :headers => {'Content-Type'=>'text/html'}, :body => 'not-a-json-response')
      $stdout.stub(:puts) # Suppress logging to keep rspec output looking tidy
      
      forecast = @forecaster.get_forecast @location_id
    end
    
    it "should cope gracefully when the day forecast contains no weather data" do
      stub_request(:get, "http://datapoint.metoffice.gov.uk/public/data/val/wxfcs/all/json/3072?key=#{@api_key}&res=daily")
        .to_return(:status => 200, :headers => {'Content-Type'=>'text/html'}, :body => @stub_forecast_nodata)
      $stdout.stub(:puts) # Suppress logging to keep rspec output looking tidy
      
      forecast = @forecaster.get_forecast @location_id
    end
    
    it "should cope gracefully when the 3hourly forecast isn't available" do
      stub_request(:get, "http://datapoint.metoffice.gov.uk/public/data/val/wxfcs/all/json/3072?key=#{@api_key}&res=3hourly")
        .to_return(:status => 404, :headers => {'Content-Type'=>'text/html'}, :body => '')
      $stdout.stub(:puts) # Suppress logging to keep rspec output looking tidy
      
      forecast = @forecaster.get_forecast @location_id
    end
    
    it "should cope gracefully when the 3hourly forecast is malformed" do
      stub_request(:get, "http://datapoint.metoffice.gov.uk/public/data/val/wxfcs/all/json/3072?key=#{@api_key}&res=3hourly")
        .to_return(:status => 200, :headers => {'Content-Type'=>'text/html'}, :body => 'not-a-json-response')
      $stdout.stub(:puts) # Suppress logging to keep rspec output looking tidy
      
      forecast = @forecaster.get_forecast @location_id
    end

  end #Forecaster

end
