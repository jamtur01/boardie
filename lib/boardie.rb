require 'sinatra'
require 'sinatra/url_for'
require 'sinatra/static_assets'
require 'rest_client'
require 'json'
require 'yaml'

def load_configuration(file, name)
  if !File.exist?(file)
    puts "There's no configuration file at #{file}!"
    exit!
  end
  Boardie.const_set(name, YAML.load_file(file))
end

module Boardie
  class Application < Sinatra::Base

    register Sinatra::StaticAssets

    configure do
      load_configuration("config/config.yml", "APP_CONFIG")
    end

    enable :logging, :dump_errors, :raise_errors
    enable :show_exceptions

    before do
      @app_name = "Boardie"
    end

    error do
      @error = "Sorry there was a nasty error! Please let Operations know that: " + env['sinatra.error']
      erb :error
    end

    helpers do

      def cycle
        %w{even odd}[@_cycle = ((@_cycle || -1) + 1) % 2]
      end

      CYCLE = %w{even odd}

      def cycle_fully_sick
        CYCLE[@_cycle = ((@_cycle || -1) + 1) % 2]
      end

    end

    get '/' do
      output = JSON.parse(get_issues)
      @issues = output["issues"]
      erb :index
    end

    def get_issues
      @site = APP_CONFIG["redmine_site"]
      issues = RestClient.get "#{@site}/issues.json", {:params => {'key' => "#{APP_CONFIG["redmine_key"]}", 'project_id' => "#{APP_CONFIG["redmine_project"]}"}}
      return issues
    end
 end
end
