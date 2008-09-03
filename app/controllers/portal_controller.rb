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
  skip_before_filter :prepare_session
  skip_after_filter  :remove_message
  before_filter :registerable_filter

  layout 'entrance'
  verify :method => :post, :only => [ :apply_for_ldap ], :redirect_to => { :action => :index }

  # ユーザ登録の画面表示（ウィザード形式のためsessionの中により表示先切替）
  def index
    case session[:entrance_next_action] ||= :confirm
    when :confirm
      # N/A
    when :registration
      params[:write_profile] = true
      params[:hobbies] = Array.new
      @user = User.find_by_code(session[:user_code])
      @profile = UserProfile.new_default
      @user_uid = UserUid.new({ :uid => session[:user_code] })
    end
    render :action => session[:entrance_next_action]
  end

  # 利用規約の確認に同意した際に呼ばれる
  def agreement
    session[:entrance_next_action] = :registration
    redirect_to :action => :index
  end

  #ユーザ登録処理
  def apply
    params[:user][:section] = params[:new_section].tr('ａ-ｚＡ-Ｚ１-９','a-zA-Z1-9').upcase unless params[:new_section].empty?
    @user = current_user
    @user.attributes = params[:user]

    @user_uid = make_user_uid

    @profile = make_profile

    User.transaction do
      @user.user_uids << @user_uid if INITIAL_SETTINGS['nickname_use_setting'] && (params[:user_uid][:uid] != session[:user_code])

      @user.user_profile = @profile if params[:write_profile]

      @user.status = 'ACTIVE'
      @user.save!

      antenna = Antenna.new(:user_id => @user.id, :name => Admin::Setting.initial_anntena, :position => 1)

      Admin::Setting.antenna_default_group.each do |default_gid|
        if Group.count(:conditions => ["gid in (?)", default_gid]) > 0
          antenna.antenna_items.build(:value_type => "symbol", :value => "gid:"+default_gid)
        end
      end
      antenna.save!

      message = render_to_string(:partial => 'entries_template/user_signup',
                                 :locals => { :user_name => @user.name, :user_introduction => @user.user_profile.self_introduction})

      @user.create_initial_entry(message)

      UserAccess.create!(:user_id => @user.id, :last_access => Time.now, :access_count => 0)
      UserMailer.deliver_sent_signup_confirm(@user.user_profile.email, "#{root_url}mypage/manage?menu=manage_email")

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
    render :text => UserUid.check_uid(params[:uid], session[:user_code])
  end

  private
  def registerable_filter
    unless current_user.unused?
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
               <input type="button" value="戻る"  onClick="location.href = '#{url_for(:controller => :platform)}';"></input></div>
             EOS
      return false
    end
  end

  def make_profile
    params[:profile][:alma_mater] = params[:new_alma_mater] unless params[:new_alma_mater].empty?
    params[:profile][:address_2] = params[:new_address_2] unless params[:new_address_2].empty?

    profile = params[:write_profile] ? UserProfile.new(params[:profile]) : UserProfile.new
    profile.hobby = ''
    if (params[:hobbies] && params[:hobbies].size > 0 )
      profile.hobby = params[:hobbies].join(',') + ','
    end
    profile.disclosure = params[:write_profile] ? true : false
    profile
  end

  def make_user_uid
    if INITIAL_SETTINGS['nickname_use_setting']
      user_uid = UserUid.new(params[:user_uid].update(:uid_type => UserUid::UID_TYPE[:nickname]))
    else
      user_uid = UserUid.new({ :uid => session[:user_code] })
    end
    user_uid
  end
end
