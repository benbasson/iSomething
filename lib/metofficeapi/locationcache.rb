require 'thread'
require 'json'

module MetOfficeAPI
  # Location cache class, checks timeout on each retrieval
  class LocationCache

    def initialize
      @instance_cache = Hash.new
      locations_data = File.read('./config/locations.json')
      JSON.parse(locations_data).each do |location|
        @instance_cache[location['id']] = MetOfficeAPI::Location.new location['id'], location['name'], location['latitude'], location['longitude']
      end
    end

    def get_location location_id
      # Fail early for invalid arguments
      raise ArgumentError, "Provided location_id must not be Nil" unless not location_id.nil?
      raise ArgumentError, "Provided location_id must be a string" unless location_id.is_a? String
      @instance_cache.fetch(location_id)
    end

    def all_locations
      @instance_cache.clone
    end

    def has_location location_id
      raise ArgumentError, "Provided location_id must not be Nil" unless not location_id.nil?
      raise ArgumentError, "Provided location_id must be a string" unless location_id.is_a? String
      @instance_cache.has_key? location_id
    end

  end

end