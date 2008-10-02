# SKIP（Social Knowledge & Innovation Platform）
# Copyright (C) 2008  TIS Inc.
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

class PlatformController < ApplicationController
  layout false
  skip_before_filter :sso, :prepare_session
  skip_after_filter  :remove_message
  protect_from_forgery :except => [:login]

  # ログイン前画面の表示
  def index
    if (params[:return_to] == url_for(:action => :index) || params[:return_to] == '/' || params[:return_to] == nil)
      reset_session_without_flash unless session[:user_code]

      if cookies[:_sso_sid]
        if sess = Session.find(:first, :conditions => ["sid = ?", cookies[:_sso_sid]])
          session[:user_code] = sess.user_code
          session[:user_name] = sess.user_name
          session[:user_email] = sess.user_email
          session[:user_section] = sess.user_section
        else
          redirect_to :action => :logout
          return false
        end
      end

      img_files = Dir.glob(File.join(RAILS_ROOT, "public", "images", "titles", "*.{jpg,png,jpeg}"))
      @img_name = File.join("titles", File.basename(img_files[rand(img_files.size)]))

      @attentions = ["#{CUSTOM_RITERAL[:abbr_app_title]}にまだユーザ登録していません<br>プロフィール登録をしてください"] unless params[:error].blank?

      @user_code, @user_name = session[:user_code], session[:user_name]
    else
      render :action => :require_login
    end
  end

  def require_login
  end

  # ログイン処理（トップからと、require_loginからの両方からpostされる）
  # 認証後は、戻り先がある場合はそちらへ、なければデフォルトはSKIPへ遷移
  def login
    user_info = AccountAccess.auth(params[:login][:key], params[:login][:password])
    expires = params[:login_save] ? Time.now + 1.month : nil
    sso_sid = Session.create_sso_sid(user_info, SSO_KEY, expires)
    cookies["_sso_sid"] = { :expires => expires, :value => sso_sid }

    reset_session
    session[:user_code] = user_info["code"]
    session[:user_name] = user_info["name"]
    session[:user_email] = user_info["email"]
    session[:user_section] = user_info["section"]

    return_to = URI.encode(params[:return_to])
    redirect_to (return_to and !return_to.empty?) ? return_to : root_url
  rescue AccountAccess::AccountAccessException => ex
    logger.warn ex.message["message"]
    flash[:auth_fail_message] ||= ex.message
    redirect_to request.env["HTTP_REFERER"]
  end

  # ログアウト
  def logout
    Session.delete_all(["sid = ?", cookies["_sso_sid"]])
    cookies["_sso_sid"] = { :value => nil ,:expires => Time.local(1999,1,1) }
    reset_session
    redirect_to :action => "index"
  end

  # セッション中のユーザ情報を取得するためのエンドポイント
  def session_info
    if sid = params[:sso_sid] and sess = Session.find(:first, :conditions => ["sid = ?", URI.decode(sid)])
      response.headers["user_code"] = sess.user_code
      response.headers["user_name"] = sess.user_name
      response.headers["user_email"] = sess.user_email
      response.headers["user_section"] = sess.user_section
    else
      render :text => "", :status => 403
      return
    end
    render :text => ""
  end

end
