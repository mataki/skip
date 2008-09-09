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
  skip_before_filter :login_required, :only => [:first]
  skip_before_filter :prepare_session, :only => [:first]
  skip_before_filter :require_admin, :only => [:first]

  def new
    @user = Admin::User.new
    @user_profile = Admin::UserProfile.new
    @user_uid = Admin::UserUid.new
    @topics = [[_('Listing %{model}') % {:model => _('user')}, admin_users_path], _('New %{model}') % {:model => _('user')}]
  end

  def create
    begin
      Admin::User.transaction do
        @user, @user_profile, @user_uid = Admin::User.make_new_user({:user => params[:user], :user_profile => params[:user_profile], :user_uid => params[:user_uid]})
        @user.save!
      end
      flash[:notice] = _('登録しました。')
      redirect_to admin_users_path
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      render :action => 'new'
    end
  end

  def edit
    @user = Admin::User.find(params[:id])
    @user_profile = @user.user_profile
    @user_uid = @user.master_user_uid

    @topics = [[_('Listing %{model}') % {:model => _('user')}, admin_users_path],
               _('Editing %{model}') % {:model => @user.topic_title }]
  rescue ActiveRecord::RecordNotFound => e
    flash[:notice] = _('ご指定のユーザは存在しません。')
    redirect_to admin_users_path
  end

  def update
    Admin::User.transaction do
      @user, @user_profile, @user_uid = Admin::User.make_user_by_id(params)
      @user.save!
      @user_profile.save!
      @user_uid.save!
    end
    flash[:notice] = _('更新しました。')
    redirect_to admin_users_path
  rescue ActiveRecord::RecordNotFound => e
    flash[:notice] = _('ご指定のユーザは存在しません。')
    redirect_to admin_users_path
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    render :action => 'edit'
  end

  def first
    if valid_activation_code? params[:code]
      if request.get?
        @user = Admin::User.new
        @user_profile = Admin::UserProfile.new
        @user_uid = Admin::UserUid.new
        render :layout => 'admin/not_logged_in'
      else
        begin
          Admin::User.transaction do
            @user, @user_profile, @user_uid = Admin::User.make_user({:user => params[:user], :user_profile => params[:user_profile], :user_uid => params[:user_uid]}, true)
            @user.user_access = UserAccess.new :last_access => Time.now, :access_count => 0
            @user.save!
            if activation = Activation.find_by_code(params[:code])
              activation.update_attributes(:code => nil)
            end
          end
          flash[:notice] = _('登録しました。')
          redirect_to '/platform/'
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
          render :layout => 'admin/not_logged_in'
        end
      end
    else
      render :text => _('この操作は、許可されていません。'), :status => :forbidden, :layout => false
    end
  end

  def import
    if request.get? || !valid_csv?(params[:file])
      @users = []
      @topics = [[_('Listing %{model}') % {:model => _('user')}, admin_users_path], _('New user from csv')]
      return
    end
    @users = Admin::User.make_users(params[:file])
    Admin::User.transaction do
      @users.each do |user, user_profile, user_uid|
        user.save!
        unless user.new_record?
          user_profile.save!
          user_uid.save!
        end
      end
    end
    flash[:notice] = _('CSVファイルからのユーザ登録/更新に成功しました。')
    redirect_to admin_users_path
  rescue ActiveRecord::RecordInvalid,
         ActiveRecord::RecordNotSaved => e
    flash[:error] = _('CSVファイルに不正な値が含まれています。')
    @users.each {|user, user_profile, user_uid| user.valid?}
  end

  private
  def valid_activation_code? code
    return false unless code
    return true if Activation.find_by_code(code)
    false
  end

  def valid_csv?(uploaded_file)
    if uploaded_file.blank?
      flash[:error] = _('ファイルを指定して下さい。')
      return false
    end

    if uploaded_file.size == 0
      flash[:error] = _('ファイルサイズが0です。')
      return false
    end

    if uploaded_file.size > 1.megabyte
      flash[:error] = _('ファイルサイズが1MBを超えています。')
      return false
    end

    unless ['text/csv', 'application/x-csv', 'application/vnd.ms-excel'].include?(uploaded_file.content_type)
      flash[:error] = _('csvファイル以外はアップロード出来ません。')
      return false
    end
    true
  end
end
