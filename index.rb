require 'sinatra'
require 'sinatra/cookies'
require 'sinatra/reloader' if development?
require 'haml'
require 'feedjira'
require 'feedjira/parser/rss_entry'
require 'json'

require_relative 'lib/metofficeapi'

configure :production do
  require 'newrelic_rpm'
end

# Simple SAXMachine classes to parse a Media RSS <media:thumbnail/>
# TODO: Remove reliance on hardcoded namespace prefix
class RSSThumbnail
  include SAXMachine
  attribute :url
  attribute :width
  attribute :height
end

class Feedjira::Parser::RSSEntry
  elements 'media:thumbnail', :as => :thumbnails, :class => RSSThumbnail
end

# Set HAML to use double quotes for attributes
# No real reason other than aesthetically I prefer it
set :haml, :attr_wrapper => '"'
set :server, 'thin'

# Read in the API key from the local filesystme
api_key = ENV['METOFFICE_API_KEY'] || File.read('.metoffice-api-key')

# Read in list of names to randomly pick from
names = JSON::parse(File.read('./config/names.json'))

# Set up global Forecaster object
forecaster = MetOfficeAPI::Forecaster.new api_key

# Declare these globals so we can know when things were updated last
qotd_last_updated = nil
news_last_updated = nil
wotd_last_updated = nil

# 'Cache' variables
qotd_entries = []
news_entries = nil
wotd_entry = nil

get '/' do
  
  # Fetch BBC news headlines, cache for 10 minutes
  if news_last_updated.nil? or news_last_updated < Time.now - 10*60
    puts 'Updating NEWS'
    news_entries = Feedjira::Feed.fetch_and_parse('http://feeds.bbci.co.uk/news/rss.xml').entries.take(12)
    news_last_updated = Time.now
  end if

  # Fetch Quotes of the Day, cache for 60 minutes
  if qotd_last_updated.nil? or qotd_last_updated < Time.now - 60*60
    puts 'Updating QOTD'
    qotd = Feedjira::Feed.fetch_and_parse('http://www.quotationspage.com/data/qotd.rss')
    qotd_entries = []
    qotd.entries.each do |entry|
      qotd_entries << entry unless entry.published < Date.today.to_time
    end
    qotd_last_updated = Time.now
  end
  
  # Fetch Word of the Day, cache for 60 minutes
  if wotd_last_updated.nil? or wotd_last_updated < Time.now - 60*60
    puts 'Updating WOTD'
    wotd = Feedjira::Feed.fetch_and_parse('http://dictionary.reference.com/wordoftheday/wotd.rss')
    wotd_entry = wotd.entries.first
    wotd_last_updated = Time.now
  end
  
  # Basic nil check
  location_id = cookies[:location_id]
  if not location_id.nil? and not location_id.empty?
    if forecaster.is_location_valid location_id 
      forecast = forecaster.get_forecast location_id  
    end
  end
  
  # Check we have a reasonable value, otherwise ignore (behaviour will default to celcius)
  temperature_units = cookies[:temperature_units]
  if (not temperature_units === MetOfficeAPI::CELCIUS and not temperature_units === MetOfficeAPI::FAHRENHEIT)
    temperature_units = nil
  end

  # Pass in a random site name from the names file and upper-case the first letter so that it matches the 
  # lowercase "i" aesthetically
  haml :index, :locals => {
    :sitename => "i#{names.sample.titleize}",
    :news_entries => news_entries,
    :qotd_entries => qotd_entries,
    :wotd_entry => wotd_entry,
    :forecast => forecast,
    :temperature_units => temperature_units
  }
  
end

get '/forecast/forecast-settings' do

  # Sort locations and stick them out on the screen; pass through current cookie values
  # so that the UI can select the current choices by default
  locations = forecaster.location_cache.all_locations.values.sort_by {|location| location.name}
  
  haml :forecast_settings, :locals => {
    :locations => locations,
    :current_location_id => cookies[:location_id],
    :current_temperature_units => cookies[:temperature_units]
  }
  
end

get '/forecast/:location_id/:date_string/:temperature_units' do
  
  # Look up the forecast entry
  forecast = forecaster.get_forecast params[:location_id]
  forecast_day = forecast.get_forecast_day params[:date_string]
  
  # Check we have a reasonable value, otherwise ignore (behaviour will default to celcius)
  temperature_units = params[:temperature_units]
  if (not temperature_units === MetOfficeAPI::CELCIUS and not temperature_units === MetOfficeAPI::FAHRENHEIT)
    temperature_units = nil
  end
  
  # Return some HTML with full daily breakdown
  haml :forecast_full_day, :locals => {
    :forecast => forecast,
    :forecast_day => forecast_day,
    :temperature_units => temperature_units
  }
  
end

get '/service-status' do
  'Up and running'
end
