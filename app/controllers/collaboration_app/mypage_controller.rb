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

class CollaborationApp::MypageController < ApplicationController
  def feed
    CollaborationApp.new(params[:app_name], params[:path]).feed_items_by_user(current_user) do |result, feed_items|
      if result
        render :partial => 'collaboration_app/shared/feed', :locals => {:feed_items => feed_items}, :layout => false
      else
        render :text => _('取得できませんでした。')
      end
    end
  end
end
