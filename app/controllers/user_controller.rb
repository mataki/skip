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

class UserController < ApplicationController
  include UserHelper

  before_filter :load_user, :setup_layout

  # tab_menu
  def group
    @groups = @user.groups.active.partial_match_name_or_description(params[:keyword]).
      categorized(params[:group_category_id]).order_active.paginate(:page => params[:page], :per_page => 50)

    flash.now[:notice] = _('No matching groups found.') if @groups.empty?
  end

private
  def setup_layout
    @title = user_title @user
    @main_menu = user_main_menu @user
    @tab_menu_option = tab_menu_option
  end

  def tab_menu_option
    { :uid => @user.uid }
  end
end
