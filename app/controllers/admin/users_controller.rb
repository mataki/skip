# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008 TIS Inc.
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

class Admin::UsersController < Admin::ApplicationController
  include AdminModule::AdminRootModule

  skip_before_filter :sso, :only => [:first]
  skip_before_filter :prepare_session, :only => [:first]
  skip_before_filter :require_admin, :only => [:first]

  undef create

  def first
    if valid_activation_code? params[:code]
      if request.get?
        @user = User.new
        @user_profile = UserProfile.new
        @user_uid = UserUid.new
        render :layout => false
      else
        begin
          User.transaction do
            @user = User.new params[:user]
            @user.admin = true
            @user.status = 'ACTIVE'
            @user_profile = UserProfile.new params[:user_profile]
            @user_profile.disclosure = true
            @user.user_profile = @user_profile
            @user_uid = UserUid.new :uid => params[:user_uid][:uid], :uid_type => 'MASTER'
            @user.user_uids << @user_uid
            @user.user_access = UserAccess.new :last_access => Time.now, :access_count => 0
            @user.save!
            UserAccess.create!(:user_id => @user.id, :last_access => Time.now, :access_count => 0)
            if activation = Activation.find_by_code(params[:code])
              activation.update_attributes(:code => nil)
            end
          end
          render :text => '登録しました。'
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
          render :layout => false
        end
      end
    else
      render :text => _('この操作は、許可されていません。'), :status => :forbidden, :layout => false
    end
  end

  private
  def valid_activation_code? code
    return false unless code
    return true if Activation.find_by_code(code)
    false
  end
end
