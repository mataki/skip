# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
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
  include ExceptionNotifiable if SkipEmbedded::InitialSettings['exception_notifier']['enable']

  helper :all

  layout 'layout'

  filter_parameter_logging :password

  protect_from_forgery

  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    if request.env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
      render :text => _('Invalid session. You need to log in again.'), :status => :bad_request
    else
      redirect_to_with_deny_auth
    end
  end

  before_filter :sso, :login_required, :prepare_session
  # FIXME 1.7で削除する。migrateによるデータ移行を行わないので。
  after_filter  :remove_message

  init_gettext "skip" if defined? GetText

  helper_method :scheme, :endpoint_url, :identifier, :checkid_request, :extract_login_from_identifier, :logged_in?, :current_user, :current_target_user, :current_target_group, :current_participation
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
    logger.info(user.to_s_log('[Log for inspection]'))

    unless controller_name == 'pictures' && action_name == 'picture'
      UserAccess.update_all(["last_access = ? ", Time.now ], ["user_id = ? ", user.id ])
      @site_count = SiteCount.find(:first, :order => "created_on desc") || SiteCount.new
    end

    # Settingのキャッシュをチェックする
    Admin::Setting.check_cache

    # mypage/welcome を表示した際は、セッション情報を最新にするため
    session[:prepared] = nil if controller_name == 'mypage' && action_name == 'welcome'
    return true if session[:prepared]

    session[:prepared] = true
    session[:user_id] = user.id
    session[:user_symbol] = user.symbol
    session[:uid] = user.uid
    session[:load_time] = Time.now

    return true
  end

  def remove_message
    return true unless logged_in?

    Message.find_all_by_user_id(current_user.id).each do |message|
      # TODO: ver1.0のデータ構造との兼ね合いで URL全体 と PATHの部分 のみの両方でマッチングしているが
      #       ver1.2とかになると URL全体 だけで判断すればよい
      if message.link_url == request.request_uri or message.link_url == request.url
        message.destroy
      end
    end
  end

  def remove_system_message
    if params[:system_message_id] && sm = current_user.system_messages.find_by_id(params[:system_message_id])
      sm.destroy
    end
  end

  def setup_custom_cookies(custom)
    cookies[:editor_mode] = {
      :value => custom.editor_mode,
      :expires => 1.month.from_now
    }
  end

  def logged_in?
    !!current_user
  end

  def current_user
    @current_user ||= (login_from_session || login_from_cookie)
  end

  def current_user=(user)
    if user
      session[:auth_session_token] = user.update_auth_session_token!
      session[:user_code] = user.code
      setup_custom_cookies(user.custom)
      @current_user = user
    else
      @current_user = nil
    end
  end

  def current_target_user
    @current_target_user ||= User.find_by_uid(params[:uid] || params[:user_id])
  end

  def current_target_group
    @current_target_group ||= Group.active.find_by_gid(params[:gid] || params[:group_id])
  end

  def current_participation
    @current_participation ||= current_target_group.group_participations.find_by_user_id(current_user.id) if current_target_group
  end

  #記事へのパーミッションをチェック
  def check_entry_permission
    find_params = BoardEntry.make_conditions(current_user.belong_symbols, {:id=>params[:id]})
    unless entry = BoardEntry.find(:first, :conditions => find_params[:conditions], :include => find_params[:include])
      return false
    end
    entry
  end

  def login_required
    unless logged_in?
      if request.env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
        render :text => _('Session expired. You need to log in again.'), :status => :bad_request
      else
        if request.url == root_url
          redirect_to :controller => '/platform', :action => :index
        else
          redirect_to :controller => '/platform', :action => :require_login, :return_to => URI.decode(request.url)
        end
      end
      false
    else
      true
    end
  end

  def redirect_to_with_deny_auth(url = { :controller => :mypage, :action => :index })
    flash[:warn] = _('Operation unauthorized.')
    redirect_to url
  end

  # exception_notification用にオーバーライド
  def rescue_action_in_public ex
    case ex
    when ActionController::UnknownController, ActionController::UnknownAction,
      ActionController::RoutingError, ActiveRecord::RecordNotFound
      render_404
    else
      render :template => "system/500" , :status => :internal_server_error

      if SkipEmbedded::InitialSettings['exception_notifier']['enable']
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
    true
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
    SkipEmbedded::InitialSettings['protocol']
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

  def secret_checker
    if !SkipEmbedded::InitialSettings['wiki'] or !SkipEmbedded::InitialSettings['wiki']['use']
      redirect_to root_url
    end
  end

  private
  def sso
    if login_mode?(:fixed_rp) and !logged_in?
      if request.env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
        render :text => _('Session expired. You need to log in again.'), :status => :bad_request
      else
        redirect_to :controller => '/platform', :action => :login, :openid_url => SkipEmbedded::InitialSettings['fixed_op_url'], :return_to => URI.encode(request.url)
      end
      return false
    end
    true
  end

  def msie?(version = 6)
    !!(request.env["HTTP_USER_AGENT"]["MSIE #{version}"])
  end
end
