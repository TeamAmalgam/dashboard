require "./app"
require "rack/contrib"
require "rack/ssl-enforcer"

$stdout.sync = true

use Rack::SslEnforcer, :except_environments => 'development'
use Rack::Deflater
use Rack::StaticCache, :urls => ["/img", "/css", "/js"], :root => "public"

run Sinatra::Application
