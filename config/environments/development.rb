# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes     = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils        = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false
config.action_view.debug_rjs                         = true

# ActionController::Base.relative_url_root = (ENV["RELATIVE_URL_ROOT"] || "")

config.logger = Logger.new(config.log_path, 1, 10.megabytes)

config.action_mailer.delivery_method = :test

config.gem 'haml', :version => '2.2.17'
#config.gem "josevalim-rails-footnotes",  :lib => "rails-footnotes", :source => "http://gems.github.com"
config.gem 'bullet', :source => 'http://gemcutter.org'
config.after_initialize do
  Bullet.enable = true
#  Bullet.alert = true
  Bullet.bullet_logger = true
  Bullet.console = true
#  Bullet.rails_logger = true
  Bullet.disable_browser_cache = true
  begin
    require 'ruby-growl'
    Bullet.growl = true
  rescue MissingSourceFile
  end
end

