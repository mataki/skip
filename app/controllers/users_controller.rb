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

class UsersController < ApplicationController
  before_filter :setup_layout

  # tab_menu
  def index
    @search = User.tagged(params[:tag_words], params[:tag_select]).profile_like(params[:profile_master_id], params[:profile_value]).descend_by_user_access_last_access.search(params[:search])
    @search.exclude_retired ||= '1'
    user_ids = @search.paginate_without_retired_skip(:all, {:include => %w(user_access), :page => params[:page]}).map(&:id)
    # 上記のみでは検索条件や表示順の条件によって、user_uidsがMASTERかNICKNAMEのどちらかしたロードされない。
    # そのためviewで正しく描画するためにidのみ条件にして取得し直す
    @users = User.id_is(user_ids).descend_by_user_access_last_access.paginate_without_retired_skip(:all, {:include => %w(user_access user_uids picture), :page => params[:page]})

    flash.now[:notice] = _('User not found.') if @users.empty?
    @tags = ChainTag.popular_tag_names
    params[:tag_select] ||= "AND"
  end

private
  def setup_layout
    @main_menu = @title = _('Users')
  end
end

