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
  include OpenidServerSystem
  include ExceptionNotifiable if INITIAL_SETTINGS['exception_notifier']['enable']
  layout 'layout'
  filter_parameter_logging :password

  protect_from_forgery
  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    redirect_to_with_deny_auth
  end

  before_filter :sso, :login_required, :prepare_session
  after_filter  :remove_message

  init_gettext "skip"

  helper_method :scheme, :endpoint_url, :identifier, :checkid_request, :extract_login_from_identifier
protected
  include InitialSettingsHelper
  # アプリケーションで利用するセッションの準備をする
  # フィルタで毎アクセスごとに確認し、セッションが未準備なら初期値をいれる
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

    @favorite_groups = []
    GroupCategory.find(:all).each do |category|
      groups = Group.find(:all,
                          :conditions => ["group_category_id = ? and group_participations.user_id = ? and group_participations.favorite = true", category.id, user.id],
                          :order => "group_participations.created_on DESC",
                          :include => :group_participations)
      @favorite_groups << {:name => category.name, :groups => groups} if groups.size > 0
    end

    # Settingのキャッシュをチェックする
    Admin::Setting.check_cache

    # mypage/welcome を表示した際は、セッション情報を最新にするため
    session[:prepared] = nil if controller_name == 'mypage' && action_name == 'welcome'
    return true if session[:prepared]

    user_custom = (UserCustom.find_by_user_id(user.id) || UserCustom.new)

    session[:prepared] = true
    session[:user_custom_theme] = user_custom.theme
    session[:user_custom_classic] = user_custom.classic
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
    @login_user_symbols ||= current_user.belong_symbols
  end

  # ログイン中のユーザの所属するグループのSymbolの配列
  def login_user_groups
    @login_user_groups ||= current_user.group_symbols
  end

  def logged_in?
    !!session[:user_code]
  end

  def current_user
    @current_user ||= (login_from_session || login_from_cookie)
  end

  def current_user=(user)
    session[:auth_session_token] = user ? user.update_auth_session_token! : nil
    session[:user_code] = user ? user.code : nil
    @current_user = user || nil
  end

  #記事へのパーミッションをチェック
  def check_entry_permission
    find_params = BoardEntry.make_conditions(login_user_symbols, {:id=>params[:id]})
    unless entry = BoardEntry.find(:first, :conditions => find_params[:conditions], :include => find_params[:include])
      return false
    end
    entry
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

  def redirect_to_with_deny_auth(url = { :controller => :mypage, :action => :index })
    flash[:warning] = _('この操作は、許可されていません。')
    redirect_to url
  end

  # 本番環境でのエラー画面をプラットホームにあるエラー画面にするために、rescue.rbのメソッドを
  # オーバーライドしている。
  # CGI::Session::CookieStore::TamperedWithCookie について
  # Rails2.0からcookie-sessionになり、以下の場合などにunmarcial出来ない場合にエラーがraiseされる。
  # (cookieのシークレットキーが変わったとき、ユーザが無理やりcookieを書き換えたとき)
  # その場合、SSOの機構があるので一旦リダイレクトして同じURLに飛ばすことでcookieを作り直せる。
  def rescue_action_in_public ex
    case ex
    when ActionController::UnknownController, ActionController::UnknownAction,
      ActionController::RoutingError, ActiveRecord::RecordNotFound
      render :file => File.join(RAILS_ROOT, 'public', '404.html'), :status => :not_found
    when CGI::Session::CookieStore::TamperedWithCookie
      redirect_to request.env["REQUEST_URI"], :status => :temporary_redirect
    else
      render :template => "system/500" , :status => :internal_server_error

      if INITIAL_SETTINGS['exception_notifier']['enable']
        deliverer = self.class.exception_data
        data = case deliverer
          when nil then {}
          when Symbol then send(deliverer)
          when Proc then deliverer.call(self)
        end

        ExceptionNotifier.deliver_exception_notification(ex, self, request, data)
      end
    end
  end

  def render_404
    respond_to do |format|
      format.html { render :file => File.join(RAILS_ROOT, 'public', '404.html'), :status => :not_found }
      format.all { render :nothing => true, :status => :not_found }
    end
  end

  # 本番環境(リバースプロキシあり)では、リモートからのリクエストでもリバースプロキシで、
  # ハンドリングされるので、ローカルからのリクエストとRailsが認識していう場合がある。
  # (lighttpd の mod_extfoward が根本の問題)
  # そもそも、enviromentの設定でどのエラー画面を出すかの設定は可能で、本番環境で詳細な
  # エラー画面を出す必要は無いので、常にリモートからのアクセスと認識させるべき。
  # なので、rescue.rb local_requestメソッドをオーバーライドしている。
  def local_request?
    false
  end

  # restful_authenticationが生成するlib/authenticated_system.rbから「次回から自動的にログイン」機能
  # に必要な箇所を持ってきた。
  def login_from_session
    User.find_by_auth_session_token(session[:auth_session_token]) if session[:auth_session_token]
  end

  def login_from_cookie
    user = cookies[:auth_token] && User.find_by_remember_token(cookies[:auth_token])
    if user && user.remember_token?
      handle_remember_cookie! false
      user
    end
  end

  #
  # Remember_me Tokens
  #
  # Cookies shouldn't be allowed to persist past their freshness date,
  # and they should be changed at each login

  # Cookies shouldn't be allowed to persist past their freshness date,
  # and they should be changed at each login

  def valid_remember_cookie?
    return nil unless @current_user
    (@current_user.remember_token?) &&
      (cookies[:auth_token] == @current_user.remember_token)
  end

  # Refresh the cookie auth token if it exists, create it otherwise
  def handle_remember_cookie! new_cookie_flag
    return unless @current_user
    case
    when valid_remember_cookie? then @current_user.refresh_token # keeping same expiry date
    when new_cookie_flag        then @current_user.remember_me
    else                             @current_user.forget_me
    end
    send_remember_cookie!
  end

  def kill_remember_cookie!
    cookies.delete :auth_token
  end

  def logout_killing_session!(keeping = [])
    h = Hash[*keeping.inject([]) do |result, item|
               result << item << session[item] if session[item]
               result
             end
            ]
    @current_user.forget_me if @current_user.is_a? User
    kill_remember_cookie!
    reset_session
    h.each do |key, val|
      session[key] = val
    end
  end

  def send_remember_cookie!
    cookies[:auth_token] = {
      :value   => @current_user.remember_token,
      :expires => @current_user.remember_token_expires_at }
  end

  # ファイルアップロード時の共通チェック
  def valid_upload_file? file, max_size = 209715200
    file.is_a?(ActionController::UploadedFile) && file.size > 0 && file.size < max_size
  end

  # 複数ファイルアップロード時の共通チェック
  def valid_upload_files? files, max_size = 209715200
    files.each do |key, file|
      return false unless valid_upload_file?(file, max_size)
    end
    return true
  end

  def scheme
    INITIAL_SETTINGS['use_ssl'] ? 'https' : 'http'
  end

  def endpoint_url
    server_url(:protocol => scheme)
  end

  def identifier(user)
    user_str = user.is_a?(User) ? user.code : user
    identity_url(:user => user_str, :protocol => scheme)
  end

  def checkid_request
    unless @checkid_request
      req = openid_server.decode_request(current_openid_request.parameters) if current_openid_request
      @checkid_request = req.is_a?(OpenID::Server::CheckIDRequest) ? req : false
    end
    @checkid_request
  end

  def current_openid_request
    @current_openid_request ||= OpenIdRequest.find_by_token(session[:request_token]) if session[:request_token]
  end

  def extract_login_from_identifier(openid_url)
    openid_url.gsub(identifier(''), '')
  end

  private
  def sso
    if login_mode?(:fixed_rp) and !logged_in?
      redirect_to :controller => '/platform', :action => :login, :openid_url => INITIAL_SETTINGS['fixed_op_url'], :return_to => URI.encode(request.url)
      return false
    end
    true
  end
end
