module MetOfficeAPI
  # Location cache class, checks timeout on each retrieval
  class LocationCache
    
    REFRESH_TIMEOUT_SECONDS = 72*60*60 # 72 hours
    
    attr_accessor :last_location_update
    
    def initialize api_key
      @api_key = api_key
      check_for_update
    end
    
    def check_for_update
      time = Time.now
      if @last_location_update.nil? or @last_location_update + REFRESH_TIMEOUT_SECONDS < time
        local_cache = Hash.new
        locations = MetofficeDatapoint.new(api_key: @api_key).forecasts_sitelist['Locations']['Location']
        locations.each do |location|
          local_cache[location['id']] = MetOfficeAPI::Location.new location['id'], location['name'], location['latitude'], location['longitude']
        end
        @instance_cache = local_cache
        @last_location_update = time
      end
    end
    
    def get_location location_id
      # Fail early for invalid arguments
      raise ArgumentError, "Provided location_id must not be Nil" unless not location_id.nil?
      raise ArgumentError, "Provided location_id must be a string" unless location_id.is_a? String
      # If argument looks legit, check for updates and return
      # NB: fetch raises KeyError if key not found
      check_for_update 
      @instance_cache.fetch(location_id)
    end
    
    def all_locations 
      check_for_update
      @instance_cache.clone
    end
    
    def has_location location_id
      raise ArgumentError, "Provided location_id must not be Nil" unless not location_id.nil?
      raise ArgumentError, "Provided location_id must be a string" unless location_id.is_a? String
      check_for_update
      @instance_cache.has_key? location_id
    end
    
  end
  
end