require 'sinatra'
require 'sinatra/cookies'
require 'sinatra/reloader' if development?
require 'haml'
require 'feedjira'
require 'feedjira/parser/rss_entry'
require 'json'
require 'redcarpet'

require_relative 'lib/metofficeapi'
require_relative 'rsscache'

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

helpers do
  def get_thumbnail entry
    if entry.thumbnails.present?
      last_thumb = entry.thumbnails.last
      return last_thumb.url unless last_thumb.nil?
    end
    return '/images/nothumb.jpg'
  end
end

configure :production do
  require 'newrelic_rpm'
end

configure do
  # Set HAML to use double quotes for attributes
  # No real reason other than aesthetically I prefer it
  set :haml, :attr_quote => '"'
  set :static_cache_control, [:public, max_age: 60 * 60 * 24 * 7 * 52]

  # Put these cache objects in as global settings, bit dirty but effective and safe
  set :bbc_news_cache, RSSCache.new('http://feeds.bbci.co.uk/news/rss.xml', {
    :timeout_secs => 10*60, # 10 minutes
    :filter => lambda do |entries| entries.take 13 end
  })

  set :qotd_cache, RSSCache.new('http://www.quotationspage.com/data/qotd.rss', {
    :timeout_secs => 60*60, # 1 hour
    :filter => lambda do |entries|
      today_entries = entries.select{|entry| entry.published >= Date.today.to_time}
      if today_entries.empty?
        today_entries = entries.select{|entry| entry.published >= Date.yesterday.to_time}
      end
      return today_entries
    end
  })

  set :wotd_cache, RSSCache.new('https://wordsmith.org/awad/rss1.xml', {
    :timeout_secs => 60*60, # 1 hour
    :filter => lambda do |entries|
      temp_entries = [entries.first]
    end
  })

  # Read in list of names to randomly pick from
  set :names, JSON::parse(File.read('./config/names.json'))

  # Read in the API key from the local filesystme
  api_key = ENV['METOFFICE_API_KEY'] || File.read('.metoffice-api-key')

  # Set up global Forecaster object
  set :forecaster, MetOfficeAPI::Forecaster.new(api_key)

end

get '/' do
  # Dereference from settings
  forecaster = settings.forecaster

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
    :sitename => "i#{settings.names.sample.titleize}",
    :news_entries => settings.bbc_news_cache.get,
    :qotd_entries => settings.qotd_cache.get,
    :wotd_entry => settings.wotd_cache.get.first,
    :forecast => forecast,
    :temperature_units => temperature_units
  }

end

get '/forecast/forecast-settings' do

  # Sort locations and stick them out on the screen; pass through current cookie values
  # so that the UI can select the current choices by default
  locations = settings.forecaster.location_cache.all_locations.values.sort_by {|location| location.name}

  haml :forecast_settings, :locals => {
    :locations => locations,
    :current_location_id => cookies[:location_id],
    :current_temperature_units => cookies[:temperature_units]
  }

end

get '/forecast/:location_id/:date_string/:temperature_units' do

  # Look up the forecast entry
  forecast = settings.forecaster.get_forecast params[:location_id]
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
  "Up and running: #{Time.now.to_formatted_s :db}"
end
