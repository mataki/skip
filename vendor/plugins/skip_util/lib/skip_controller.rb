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
  private
  def sso
    unless cookies[:_sso_sid]
      redirect_to "#{ENV['SKIP_URL']}/platform/require_login?return_to=#{URI.encode(request.env["REQUEST_URI"])}"
      return false
    end

    if session[:sso_sid] != cookies[:_sso_sid]
      reset_session
      begin
        open(ENV['SKIP_URL'] + "/session/" + cookies[:_sso_sid], :proxy => nil) do |f|
          session[:sso_sid] = cookies[:_sso_sid]
          session[:user_code] = URI.decode(f.meta["user_code"])
          session[:user_name] = URI.decode(f.meta["user_name"])
          session[:user_email] = URI.decode(f.meta["user_email"])
          session[:user_section] = URI.decode(f.meta["user_section"])
        end
      rescue OpenURI::HTTPError => error
        redirect_to ENV['SKIP_URL'] + "/logout"
        return false
      end
    end
    return true
  end

end
