class Apps::JavascriptsController < Apps::ApplicationController
  @@last_started_date = Time.now
  %w(application).each do |method_name|
    define_method method_name do
      if stale?(:last_modified => @@last_started_date)
        proxy_request_to_simple_apps
      end
    end
  end
end
