require "./app"
require "rack/contrib"

$stdout.sync = true

use Rack::Deflater
use Rack::StaticCache, :urls => ["/img", "/css", "/js"], :root => "public"

run Sinatra::Application
