require "./app"

$stdout.sync = true

use Rack::Deflater

run Sinatra::Application
