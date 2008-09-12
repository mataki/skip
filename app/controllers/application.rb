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

require 'symbol'
require 'tempfile'

class ApplicationController < ActionController::Base
  protect_from_forgery

  layout 'layout'
  before_filter :login_required, :prepare_session
  after_filter  :remove_message

  init_gettext "skip"

  # アプリケーションで利用するセッションの準備をする
  # フィルタで毎アクセスごとに確認し、セッションが未準備なら初期値をいれる
  # skip_utilで認証がされている前提で、グローバルセッションを利用している
  def prepare_session
    user = current_user

    # プロフィール情報が登録されていない場合、platformに戻す
    unless user.active?
      redirect_to user.retired? ? { :controller => '/platform', :action => :logout, :message => 'retired' } : { :controller => '/portal' }
      return
    end

    # ログのリクエスト情報に、ユーザ情報を加える（情報漏えい事故発生時のトレーサビリティを確保)
    logger.info("  Log_for_Inspection: {\"user_id\"=>\"#{session[:user_id]}\", \"uid\"=>\"#{session[:uid]}\"}")

    unless controller_name == 'pictures'
      UserAccess.update_all("last_access = CURRENT_TIMESTAMP", ["user_id = ? ", user.id ])
      @site_count = SiteCount.find(:first, :order => "created_on desc") || SiteCount.new
    end

    # Settingのキャッシュをチェックする
    Admin::Setting.check_cache

    # mypage/welcome を表示した際は、セッション情報を最新にするため
    session[:prepared] = nil if controller_name == 'mypage' && action_name == 'welcome'
    return true if session[:prepared]

    session[:prepared] = true
    session[:user_custom_theme] = (UserCustom.find_by_user_id(user.id) || UserCustom.new).theme
    session[:user_id] = user.id
    session[:user_symbol] = user.symbol
    session[:uid] = user.uid
    session[:load_time] = Time.now

    return true
  end

  def remove_message
    return true unless session[:user_id]

    server_addr = request.protocol+ request.host_with_port + request.relative_url_root
    if headers["Status"].to_s.split(" ").first == "302" #redirect
      current_url = headers["location"].gsub(server_addr, "") if headers["location"]
    else
      current_url = request.env["REQUEST_URI"].gsub(server_addr,"") if request.env["REQUEST_URI"]
    end

    Message.get_message_array_by_user_id(session[:user_id]).each do |message|
      if message[:link_url] == current_url
        Message.delete_all(["link_url = ? and user_id = ?", current_url, session[:user_id]])
      end
    end
  end

  # ログイン中のユーザのシンボル＋そのユーザの所属するグループのSymbolの配列を返す
  # sid:all_userは含めていない
  def login_user_symbols
    @login_user_symbols ||= [session[:user_symbol]] + login_user_groups
  end

  # ログイン中のユーザの所属するグループのSymbolの配列
  def login_user_groups
    @login_user_groups ||= GroupParticipation.get_gid_array_by_user_id(session[:user_id])
  end

  def logged_in?
    !!session[:user_code]
  end

  def current_user
    @current_user ||= User.find_by_code(session[:user_code])
  end

  #エントリへのパーミッションをチェック
  def check_entry_permission
    find_params = BoardEntry.make_conditions(login_user_symbols, {:id=>params[:id]})
    unless entry = BoardEntry.find(:first, :conditions => find_params[:conditions], :include => find_params[:include])
      return false
    end
    entry
  end

  def require_admin
    unless current_user.admin
      redirect_to root_url
      return false
    end
  end

  def login_required
    if current_user.nil?
      if request.url == root_url
          redirect_to :controller => '/platform', :action => :index
        else
          redirect_to :controller => '/platform', :action => :require_login, :return_to => URI.encode(request.url)
        end
      return false
    end
    true
  end
end
