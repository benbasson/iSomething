require './index'
require 'rack/contrib'

# GZip
use Rack::Deflater

run Sinatra::Application
$stdout.sync = true
$stderr.sync = true