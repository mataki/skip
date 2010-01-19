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

module CollaborationApp
  module Oauth
    class Backend
      def initialize name
        @name = name
      end

      def add_access_token(identity_url, token, secret)
        if user = User.find_by_openid_identifier(identity_url)
          if oauth_access = UserOauthAccess.find_by_app_name_and_user_id(@name, user.id)
            oauth_access.update_attributes! :token => token, :secret => secret
          else
            user.user_oauth_accesses.create! :app_name => @name, :token => token, :secret => secret
          end
        end
      end

      def update_user(identity_url, data)
        :noop
      end

      def update_group(gid, data)
        :noop
      end
    end
  end
end
