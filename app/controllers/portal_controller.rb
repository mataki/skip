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

# プロフィール情報を登録するためのアクションをまとめたクラス
class PortalController < ApplicationController
  verify :method => :post, :only => [:registration ], :redirect_to => { :action => :index }

  skip_before_filter :prepare_session
  skip_before_filter :sso, :only => [:registration]
  skip_before_filter :login_required, :only => [:registration]
  skip_before_filter :valid_tenant_required, :only => [:registration]
  before_filter :registerable_filter

  def registration
    if session[:identity_url].blank?
      flash[:notice] = _('You must login with openid.')
      redirect_to :controller => :platform, :action => :index
    else
      @user = User.create_with_identity_url(session[:identity_url], params[:user].update(:tenant => current_tenant))
      if @user.valid?
        reset_session
        session[:entrance_next_action] = :registration
        self.current_user = @user
        redirect_to :action => :index
      else
        @error_msgs = []
        @error_msgs.concat @user.errors.full_messages.reject{|msg| msg.include?("User uid") } unless @user.valid?
        render :action => :account_registration
      end
    end
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
