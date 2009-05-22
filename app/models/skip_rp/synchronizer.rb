module SkipRp
  module Synchronizer
    def service
      # TODO collaboration_appsが未設定時の処理をどうするか検討
      # if collaboration_apps = INITIAL_SETTINGS['collaboration_apps']
      collaboration_apps = INITIAL_SETTINGS['collaboration_apps']
      app = collaboration_apps[@name]
      if provider = OauthProvider.find_by_app_name(@name)
        SkipRp::Service.new(@name, app['url'], :key => provider.token, :secret => provider.secret)
      else
        service = SkipRp::Service.register!(@name, app['url'], :url => "#{INITIAL_SETTINGS['protocol']}#{INITIAL_SETTINGS['host_and_port']}")
        OauthProvider.create! :app_name => @name, :token => service.key, :secret => service.secret
        service
      end
    end
  end
end
