module MetOfficeAPI
  
  # Simple location object
  class Location
    
    attr_accessor :id, :name, :latitude, :longitude
    
    def initialize location_id, location_name, latitude, longitude
      @id = location_id
      @name = location_name
      @latitude = latitude
      @longitude = longitude
    end
    
  end
  
end