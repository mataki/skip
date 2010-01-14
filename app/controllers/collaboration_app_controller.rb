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

class CollaborationAppController < ApplicationController
  def feed
    path_with_query = params[:gid] ? "#{params[:path]}?skip_gid=#{params[:gid]}" : params[:path]
    UserOauthAccess.resource(params[:app_name], current_user, path_with_query) do |result, body|
      if result
        @feed_items = UserOauthAccess.sorted_feed_items(body, 5)
        render :layout => false
      else
        render :text => _('Retrieval failed.')
      end
    end
  end
end
