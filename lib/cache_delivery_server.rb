File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require File.dirname(__FILE__) + '/../config/environment'

require "mongrel"

host = "0.0.0.0"
port = 3002
cache_dir = File.join(RAILS_ROOT, SkipEmbedded::InitialSettings['cache_path'])

config = Mongrel::Configurator.new :host => host, :port => port do
  listener { uri "/", :handler => Mongrel::DirHandler.new(cache_dir) }
  trap("INT") { stop }
  run
end

puts "Mongrel running on #{host}:#{port} with docroot #{cache_dir}"
config.join
