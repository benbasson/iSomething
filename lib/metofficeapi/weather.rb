module MetOfficeAPI
  
  WEATHER_IMAGES = {
    0  => 'clearnight.png',
    1  => 'clear.png',
    2  => 'partlycloudynight.png', #Night 
    3  => 'partlycloudy.png', #Day
    5  => 'fog.png',
    6  => 'fog.png',
    7  => 'cloudy.png',
    8  => 'scatteredclouds.png',
    9  => 'rainnight.png', #Night
    10 => 'rain02.png', #Day
    11 => 'rain02.png',
    12 => 'rain02.png',
    13 => 'rain03.png', #Night
    14 => 'rain03.png', #Day
    15 => 'rain03.png',
    16 => 'sleet.png', #Night
    17 => 'sleet.png', #Day
    18 => 'sleet.png',
    19 => 'hail.png', #Night
    20 => 'hail.png', #Day
    21 => 'hail.png',
    22 => 'snownight.png', #Night
    23 => 'snow01.png', #Day
    24 => 'snow01.png',
    25 => 'snow.png', #Night
    26 => 'snow.png', #Day
    27 => 'snow.png',
    28 => 'thunderstorms01.png', #Night
    29 => 'thunderstorms01.png', #Day
    30 => 'storms.png'
  }.freeze
  
  WEATHER_TYPES = {
    0  => 'Clear', #Night
    1  => 'Sunny', #Day
    2  => 'Partly Cloudy', #Night 
    3  => 'Partly Cloudy', #Day
    5  => 'Mist',
    6  => 'Fog',
    7  => 'Cloudy',
    8  => 'Overcast',
    9  => 'Light Rain Shower', #Night
    10 => 'Light Rain Shower', #Day
    11 => 'Drizzle',
    12 => 'Light Rain',
    13 => 'Heavy Rain Shower', #Night
    14 => 'Heavy Rain Shower', #Day
    15 => 'Heavy Rain',
    16 => 'Sleet Shower', #Night
    17 => 'Sleet Shower', #Day
    18 => 'Sleet',
    19 => 'Hail Shower', #Night
    20 => 'Hail Shower', #Day
    21 => 'Hail',
    22 => 'Light Snow Shower', #Night
    23 => 'Light Snow Shower', #Day
    24 => 'Light Snow',
    25 => 'Heavy Snow Shower', #Night
    26 => 'Heavy Snow Shower', #Day
    27 => 'Heavy Snow',
    28 => 'Thunder Shower', #Night
    29 => 'Thunder Shower', #Day
    30 => 'Thunder'
  }.freeze
  
  CELCIUS = 'celcius'
  FAHRENHEIT = 'fahrenheit'
  
  DEFAULT_TEMPERATURE_UNIT = 'celcius'
  
  TEMPERATURE_UNITS = {
    CELCIUS => 'C',
    FAHRENHEIT => 'F' 
  }.freeze
  
end
  
