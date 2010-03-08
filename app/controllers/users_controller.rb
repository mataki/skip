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
  skip_before_filter :prepare_session, :only => %w(agreement new)
  skip_before_filter :sso, :only => %w(agreement new)
  skip_before_filter :login_required, :only => %w(agreement new)
  before_filter :registerable_filter, :only => %w(agreement new create)
  after_filter :remove_system_message, :only => %w(show)

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
    @main_menu = @title = _('Users')
  end

  def show
    # 紹介してくれた人一覧
    @against_chains = current_target_user.against_chains.order_new.limit(5)
  end

  def new
  end

  def create
  end

  def agreement
    session[:agreement] = if login_mode?(:free_rp) and !session[:identity_url].blank?
                                       :agree_with_free_rp
                                     else
                                       :agree
                                     end
    redirect_to :action => :new
  end

  private
  def registerable_filter
    if current_user and !current_user.unused?
      redirect_to root_url
      return false
    end

    if Admin::Setting.stop_new_user
      @deny_message = _("New user registration is suspended for now.")
    end
    if @deny_message
      render :action => :deny_register
      return false
    end
  end
end

