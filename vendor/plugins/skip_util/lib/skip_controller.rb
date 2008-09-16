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

class ActionController::Base
  filter_parameter_logging :password
  before_filter :sso

  rescue_from ActionController::InvalidAuthenticityToken, :with => :deny_auth

  # 本番環境でのエラー画面をプラットホームにあるエラー画面にするために、rescue.rbのメソッドを
  # オーバーライドしている。
  # CGI::Session::CookieStore::TamperedWithCookie について
  # Rails2.0からcookie-sessionになり、以下の場合などにunmarcial出来ない場合にエラーがraiseされる。
  # (cookieのシークレットキーが変わったとき、ユーザが無理やりcookieを書き換えたとき)
  # その場合、SSOの機構があるので一旦リダイレクトして同じURLに飛ばすことでcookieを作り直せる。
  def rescue_action_in_public ex
    case ex
    when ::ActionController::UnknownController,::ActionController::UnknownAction,::ActionController::RoutingError
      redirect_to "#{ENV['SKIP_URL']}/404.html", :status => :temporary_redirect
    when CGI::Session::CookieStore::TamperedWithCookie
      redirect_to request.env["REQUEST_URI"], :status => :temporary_redirect
    else
      redirect_to "#{ENV['SKIP_URL']}/500.html", :status => :temporary_redirect
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


  def verify_extension? file_name, content_type
    !['html','htm','js'].any?{|extension| extension == file_name.split('.').last } &&
      !['text/html','application/x-javascript'].any?{|content| content == content_type }
  end

  private
  def sso
    unless ENV['SKIPOP_URL'].blank?
      unless logged_in?
        redirect_to :controller => '/platform', :action => :login, :openid_url => ENV['SKIPOP_URL'], :return_to => URI.encode(request.url)
        return false
      end
      true
    end
  end

  def deny_auth
    flash[:warning] = 'この操作は、許可されていません'
    redirect_to :controller => 'mypage', :action => 'index'
  end
end
