$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "lib")))

require 'boardie'

use Rack::ShowExceptions

run Boardie::Application.new
