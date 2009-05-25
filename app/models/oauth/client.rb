# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'skip_embedded/rp_service/client'

module Oauth
  module Client
    def client(name = @name)
      # TODO collaboration_appsが未設定時の処理をどうするか検討
      # if collaboration_apps = INITIAL_SETTINGS['collaboration_apps']
      collaboration_apps = INITIAL_SETTINGS['collaboration_apps']
      app = collaboration_apps[name]
      if provider = OauthProvider.find_by_app_name(name)
        client = SkipEmbedded::RpService::Client.new(name, app['url'], :key => provider.token, :secret => provider.secret)
        client.connection = SkipEmbedded::RpService::HttpConnection.new
        client.backend = SkipOauthBackend.new(name)
        client
      else
        client = SkipEmbedded::RpService::Client.register!(name, app['url'], :url => "#{INITIAL_SETTINGS['protocol']}#{INITIAL_SETTINGS['host_and_port']}")
        OauthProvider.create! :app_name => name, :token => client.key, :secret => client.secret
        client.backend = SkipOauthBackend.new(name)
        client
      end
    end
  end
end
