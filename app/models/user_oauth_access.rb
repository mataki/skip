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

class UserOauthAccess < ActiveRecord::Base
  include Oauth::Client
  belongs_to :users

  def resource resource_path
    # TODO タイムアウト設定は別設定にしたほうがいいかも
    timeout(Admin::Setting.mypage_feed_timeout.to_i) do
      return client(self.app_name).oauth(self.token, self.secret).get_resource(resource_path)
    end
    nil
  end
end
