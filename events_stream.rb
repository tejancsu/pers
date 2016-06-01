require "rubygems"
require "bundler/setup"
require "active_record"

project_root = File.dirname(File.absolute_path(__FILE__))
Dir.glob(project_root + "/app/models/*.rb").each{|f| require f}
Dir.glob(project_root + "/lib/*.rb").each{|f| require f}
Dir.glob(project_root + "/lib/messages/*.rb").each{|f| require f}

connection_details = YAML::load(File.open('config/database.yml'))
ActiveRecord::Base.establish_connection(connection_details)
counter_cache_file = project_root+"/.counter_cache~"
processing_state_file = project_root+"/.processing_state~"

if __FILE__==$0
  if ARGV.size < 1
    puts "Must pass the input file atleast"
    exit
  end

  retry_round = (ARGV[1] && (ARGV[1] == "true"))
  EventAnalytics.new(ARGV[0], counter_cache_file, processing_state_file, retry_round).get_aggregates!
end