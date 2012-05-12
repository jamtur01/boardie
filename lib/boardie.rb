require 'sinatra'
require 'sinatra/url_for'
require 'sinatra/static_assets'
require 'rest_client'
require 'json'
require 'yaml'
require 'pp'

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
      get_issues
    end

    error do
      @error = "Sorry there was a nasty error! Please let Operations know that: " + env['sinatra.error']
      erb :error
    end

    not_found do
      "Page not found"
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
      erb :index
    end

    get %r{/stream/(.+)} do |name|
     @name = name
     if @workstreams.include? @name
       get_stream_issues(@issues)
       erb :stream
     else
       status 404
     end
    end

    def get_issues
      @site = APP_CONFIG["redmine_site"]
      redmine_data = JSON.parse(RestClient.get "#{@site}/issues.json", {:params => {'key' => "#{APP_CONFIG["redmine_key"]}", 'project_id' => "#{APP_CONFIG["redmine_project"]}", 'limit' => '200' }})
      @issues = redmine_data["issues"]
      @workstreams = get_ws(@issues)
    end

    def get_ws(issues)
      ws = []
      issues.each do |issue|
        fields = issue["custom_fields"]
        fields.each do |field|
          if field["id"] == 38
            ws << field["value"] unless ws.include? field["value"]
          end
        end
      end
      return ws.compact.reject { |s| s.nil? or s.empty? }
    end

    def get_stream_issues(issues)
      @stream_issues = []
      issues.each do |issue|
        fields = issue["custom_fields"]
        fields.each do |field|
          if field["id"] == 38 && field["value"] == @name
            pp field["value"], @name
            @stream_issues << issue
          end
        end
      end
    end
 end
end
