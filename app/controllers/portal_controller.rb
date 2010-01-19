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
  verify :method => :post, :only => [ :apply, :registration ], :redirect_to => { :action => :index }

  skip_before_filter :prepare_session
  skip_after_filter  :remove_message
  skip_before_filter :sso, :only => [:index, :agreement, :registration]
  skip_before_filter :login_required, :only => [:index, :agreement, :registration]
  before_filter :registerable_filter

  # ユーザ登録の画面表示（ウィザード形式のためsessionの中により表示先切替）
  def index
    case session[:entrance_next_action] ||= :confirm
    when :confirm
      # N/A
    when :account_registration
      @user = User.new
      session[:entrance_next_action] = :account_registration
    when :registration
      unless current_user
        flash[:error] = _('Unable to continue with the user registration process. A fresh start is required.')
        redirect_to :controller => '/platform', :action => :index
        return
      end
      @user = current_user
      @profiles = @user.user_profile_values
      @user_uid = (UserUid.new({ :uid => @user.email.split('@').first }))
    end
    render :action => session[:entrance_next_action]
  end

  # 利用規約の確認に同意した際に呼ばれる
  def agreement
    session[:entrance_next_action] = if login_mode?(:free_rp) and !session[:identity_url].blank?
                                       :account_registration
                                     else
                                       :registration
                                     end
    redirect_to :action => :index
  end

  #ユーザ登録処理
  def apply
    @user = current_user
    @user.attributes = params[:user]
    if @user.within_time_limit_of_activation_token?
      @user.crypted_password = nil
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]
    end

    @profiles = @user.find_or_initialize_profiles(params[:profile_value])

    User.transaction do
      if SkipEmbedded::InitialSettings['username_use_setting']
        @user_uid = @user.user_uids.build(params[:user_uid].update(:uid_type => UserUid::UID_TYPE[:username]))
        @user_uid.save!
      end

      @profiles.each{|profile| profile.save!}
      @user.created_on = Time.now
      @user.status = 'ACTIVE'
      @user.save!

      UserAccess.create!(:user_id => @user.id, :last_access => Time.now, :access_count => 0)
      UserMailer::Smtp.deliver_sent_signup_confirm(@user.email, @user.code, root_url)

      @user.activate!

      session[:entrance_next_action] = nil
      redirect_to :controller => 'mypage', :action => 'welcome'
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    @error_msg = []
    @error_msg.concat @user.errors.full_messages.reject{|msg| msg.include?("User uid") } unless @user.valid?
    @error_msg.concat @user_uid.errors.full_messages if @user_uid and @user_uid.errors
    @error_msg.concat SkipUtil.full_error_messages(@profiles)
    @user.status = 'UNUSED'

    render :action => :registration
  end

  # ajax_action
  # 入力されているuidがユニークか否かをチェックする
  def ado_check_uid
    unless error_message = UserUid.validation_error_message(params[:uid])
      render :text => _('Usable.'), :status => :ok
    else
      render :text => error_message, :status => :bad_request
    end
  end

  def registration
    if session[:identity_url].blank?
      flash[:notice] = _('You must login with openid.')
      redirect_to :controller => :platform, :action => :index
    else
      @user = User.create_with_identity_url(session[:identity_url], params[:user])
      if @user.valid?
        reset_session
        session[:entrance_next_action] = :registration
        self.current_user = @user
        redirect_to :action => :index
      else
        @error_msgs = []
        @error_msgs.concat @user.errors.full_messages.reject{|msg| msg.include?("User uid") } unless @user.valid?
        @error_msgs.concat @user.user_uids.first.errors.full_messages unless @user.user_uids.first.errors.empty?
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
