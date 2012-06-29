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

    configure :development do
      log = File.new("log/development.log", "a")
      STDOUT.reopen(log)
      STDERR.reopen(log)
      load_configuration("config/config.yml", "APP_CONFIG")
    end

    configure :production do
      log = File.new("log/production.log", "a")
      STDOUT.reopen(log)
      STDERR.reopen(log)
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
      property :updated_on, Date

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

    get '/' do
      expires 180, :public, :must_revalidate
      issues
      erb :index
    end

    get %r{/stream/(.+)} do |name|
     expires 180, :public, :must_revalidate
     if @workstreams.include? name
       closed_count(name)
       @stream_issues = Ticket.all(:workstream => name)
       erb :stream
     else
       status 404
     end
    end

    get %r{/engineer/(.+)} do |name|
     expires 180, :public, :must_revalidate
     if @engineers.include? name
       @engineer_issues = Ticket.all(:assigned_to => name, :status_id.not => 5)
       erb :engineer
     else
       status 404
     end
    end

    helpers do

      def cycle
        %w{even odd}[@_cycle = ((@_cycle || -1) + 1) % 2]
      end

      CYCLE = %w{even odd}

      def cycle_fully_sick
        CYCLE[@_cycle = ((@_cycle || -1) + 1) % 2]
      end

      def get_issues
        @site = APP_CONFIG["redmine_site"]
        redmine_data = JSON.parse(RestClient.get "#{@site}/issues.json", {:params => {'key' => "#{APP_CONFIG["redmine_key"]}", 'project_id' => "#{APP_CONFIG["redmine_project"]}", 'limit' => '200', 'status_id' => '*' }})

        redmine_data["issues"].each do |issue|
          create_record(issue)
        end

        ws = Ticket.all(:fields => [:workstream], :unique => true, :workstream.not => nil, :workstream.not => "", :status_id.not => 5)
        @workstreams = []
        ws.each do |stream|
          @workstreams << stream.workstream
        end

        oe = Ticket.all(:fields => [:assigned_to], :unique => true, :assigned_to.not => nil, :assigned_to.not => "", :status_id.not => 5)
        @engineers = []
        oe.each do |engine|
          @engineers << engine.assigned_to
        end
      end

      def closed_count(stream)
        @site = APP_CONFIG["redmine_site"]
        redmine_data = Ticket.all(:status_id => 5)

        @closed_count = redmine_data["issues"].count
      end

      def create_record(issue)
        status_id, status_name = issue["status"]["id"], issue["status"]["name"]
        if issue["assigned_to"]
          assigned = issue["assigned_to"]["name"]
        else
          assigned = nil
        end
        ws = issue["custom_fields"].detect { |f| f["id"] == 38 }
        ws = ws["value"] unless ws == nil
        ws = nil if ws == ""
        ticket = Ticket.first_or_create(:ticket_id => issue["id"]).update(
                 :ticket_id    => issue["id"],
                 :subject      => issue["subject"],
                 :status_id    => status_id,
                 :status_name  => status_name,
                 :assigned_to  => assigned,
                 :workstream   => ws,
                 :updated_on   => issue['updated_on'])
      end

      def issues
        @issues = Ticket.all
        @backlog = Ticket.all(:status_id => '8') + Ticket.all(:status_id => '10') + Ticket.all(:status_id => '17') & Ticket.all(:assigned_to => nil)
        @blocked = Ticket.all(:status_id => '11') + Ticket.all(:status_id => '12')
        @inprogress = Ticket.all(:status_id => '8') & Ticket.all(:assigned_to.not => nil)
        @overquota = true if @inprogress.count > APP_CONFIG["inprogress_quota"]
        @review = Ticket.all(:status_id => '14') + Ticket.all(:status_id => '18')
        @prod = Ticket.all(:status_id => '5')
      end
    end
 end
end
