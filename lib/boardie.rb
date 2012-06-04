require 'sinatra'
require 'sinatra/url_for'
require 'sinatra/static_assets'
require 'rest_client'
require 'data_mapper'
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
    DataMapper.setup(:default, "sqlite3:db/boardie.db")
    enable :show_exceptions

    class Ticket
      include DataMapper::Resource

      property :id, Serial
      property :ticket_id, Integer, :key => true
      property :status_id, Integer
      property :status_name, String
      property :subject, String, :length => 250
      property :assigned_to, String
      property :workstream, String

      validates_presence_of :ticket_id
    end

    DataMapper.finalize
    DataMapper.auto_upgrade!

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
      @issues = Ticket.all
      erb :index
    end

    get %r{/stream/(.+)} do |name|
     if @workstreams.include? name
       @stream_issues = Ticket.all(:workstream => name)
       erb :stream
     else
       status 404
     end
    end

    def get_issues
      @site = APP_CONFIG["redmine_site"]
      redmine_data = JSON.parse(RestClient.get "#{@site}/issues.json", {:params => {'key' => "#{APP_CONFIG["redmine_key"]}", 'project_id' => "#{APP_CONFIG["redmine_project"]}", 'limit' => '200' }})

      redmine_data["issues"].each do |issue|
        create_record(issue)
      end
      ws = Ticket.all(:fields => [:workstream], :unique => true, :workstream.not => nil, :workstream.not => "")
      @workstreams = []
      ws.each do |stream|
        @workstreams << stream.workstream
      end
    end

    def create_record(issue)
      if issue["assigned_to"]
        assigned = issue["assigned_to"]["name"]
      else
        assigned = nil
      end
      status_id, status_name = issue["status"]["id"], issue["status"]["name"]
      ws = issue["custom_fields"].detect { |f| f["id"] == 38 }
      ws = ws["value"] unless ws == nil
      ticket = Ticket.first_or_create(:ticket_id => issue["id"]).update(
                 :ticket_id    => issue["id"],
                 :subject      => issue["subject"],
                 :status_id    => status_id,
                 :status_name  => status_name,
                 :assigned_to  => assigned,
                 :workstream   => ws)
    end
 end
end
