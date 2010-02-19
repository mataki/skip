class Apps::JavascriptsController < Apps::ApplicationController
  %w(application).each do |method_name|
    define_method method_name do
      proxy_request_to_simple_apps
    end
  end
end
