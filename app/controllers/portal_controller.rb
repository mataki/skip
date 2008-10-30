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

# SNSへのプロフィール情報を登録するためのアクションをまとめたクラス
require "jcode"
class PortalController < ApplicationController
  layout 'entrance'
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
      params[:write_profile] = true
      params[:hobbies] = Array.new
      @user = current_user
      @profile = (@user.user_profile || UserProfile.new_default)
      @user_uid = (UserUid.new({ :uid => @profile.email.split('@').first }))
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
    unless @user.activation_token.nil?
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]
    end
    @user.status = 'ACTIVE'

    @profile = @user.user_profile
    @profile.attributes_for_registration(params)

    User.transaction do
      if INITIAL_SETTINGS['username_use_setting']
        @user_uid = @user.user_uids.build(params[:user_uid].update(:uid_type => UserUid::UID_TYPE[:username]))
        @user_uid.save!
      end

      @user.save!
      @profile.save!

      Antenna.create_initial(@user).save!

      message = render_to_string(:partial => 'entries_template/user_signup',
                                 :locals => { :user_name => @user.name, :user_introduction => @user.user_profile.self_introduction})
      @user.create_initial_entry(message)

      UserAccess.create!(:user_id => @user.id, :last_access => Time.now, :access_count => 0)
      UserMailer.deliver_sent_signup_confirm(@user.user_profile.email, "#{root_url}mypage/manage?menu=manage_email")

      @user.activate! unless @user.activation_token.nil?

      session[:entrance_next_action] = nil
      redirect_to :controller => 'mypage', :action => 'welcome'
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    @error_msg = []
    @error_msg.concat @user.errors.full_messages.reject{|msg| msg.include?("User uid") || msg.include?("User profile") } unless @user.valid?
    @error_msg.concat @user_uid.errors.full_messages if @user_uid and @user_uid.errors
    @error_msg.concat @profile.errors.full_messages if @profile and @profile.errors

    render :action => :registration
  end

  # ajax_action
  # 入力されているuidがユニークか否かをチェックする
  def ado_check_uid
    render :text => UserUid.check_uid(params[:uid])
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
        @error_msgs.concat @user.errors.full_messages.reject{|msg| msg.include?("User uid") || msg.include?("User profile") } unless @user.valid?
        @error_msgs.concat @user.user_uids.first.errors.full_messages unless @user.user_uids.first.errors.empty?
        @error_msgs.concat @user.user_profile.errors.full_messages unless @user.user_profile.errors.empty?
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
      deny_message = "現在、新規のユーザ登録の処理は停止させて頂いております。"
    end
    if deny_message
      render :layout => "entrance",
      :text => <<-EOS
               <div style="font-weight: bold; font-size: 18px;">大変申し訳ございません。<br/>#{deny_message}<br/>
               <input type="button" value="ログアウト"  onClick="location.href = '#{url_for(:controller => "/platform", :action => :logout)}';"></input></div>
             EOS
      return false
    end
  end
end
