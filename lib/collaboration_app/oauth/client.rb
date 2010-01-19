# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2010 TIS Inc.
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

module CollaborationApp
  module Oauth
    module Client
      def client(name = @name)
        if provider = OauthProvider.find_by_app_name(name)
          setting = provider.setting
          client = SkipEmbedded::RpService::Client.new(name, setting.root_url, :key => provider.token, :secret => provider.secret)
          client.connection = SkipEmbedded::RpService::HttpConnection.new
          client.backend = Backend.new(name)
          client
        else
          client = nil
          OauthProvider.new(:app_name => name) do |provider|
            setting = provider.setting
            client = SkipEmbedded::RpService::Client.register!(name, setting.root_url, :url => "#{SkipEmbedded::InitialSettings['protocol']}#{SkipEmbedded::InitialSettings['host_and_port']}")
            provider.token = client.key
            provider.secret = client.secret
          end.save!
          client.backend = Backend.new(name)
          client
        end
      end
    end
  end
end
