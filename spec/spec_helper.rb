require_relative '../lib/metofficeapi'
require 'webmock/rspec'

# Stop any HTTP callouts other than to localhost (everything should be mocked locally for testing)
WebMock.disable_net_connect!(allow_localhost: true)
