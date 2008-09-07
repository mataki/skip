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

require 'openid/extensions/ax'

class PlatformController < ApplicationController
  layout false
  skip_before_filter :sso, :login_required, :prepare_session
  skip_after_filter  :remove_message

  # ログイン前画面の表示
  def index
    if (params[:return_to] == url_for(:action => :index) || params[:return_to] == '/' || params[:return_to] == nil)
      reset_session_without_flash unless session[:user_code]

      img_files = Dir.glob(File.join(RAILS_ROOT, "public", "images", "titles", "*.{jpg,png,jpeg}"))
      @img_name = File.join("titles", File.basename(img_files[rand(img_files.size)]))

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
    if using_open_id?
      login_with_open_id
    else
      user_info = AccountAccess.auth(params[:login][:key], params[:login][:password])

      reset_session
      session[:user_code] = user_info["code"]
      session[:user_name] = user_info["name"]
      session[:user_email] = user_info["email"]
      session[:user_section] = user_info["section"]

      return_to = params[:return_to] ? URI.encode(params[:return_to]) : nil
      redirect_to (return_to and !return_to.empty?) ? return_to : root_url
    end
  rescue AccountAccess::AccountAccessException => ex
    logger.warn ex.message["message"]
    flash[:auth_fail_message] ||= ex.message
    redirect_to request.env["HTTP_REFERER"]
  end

  # ログアウト
  def logout
    reset_session
    redirect_to ENV['SKIPOP_URL'].blank? ? {:action => "index"} : "#{ENV['SKIPOP_URL']}logout"
  end

  private
  def login_with_open_id
    authenticate_with_open_id do |result, identity_url, registration|
      if result.successful?
        unless identifier = OpenidIdentifier.find_by_url(identity_url)
          if !ENV['SKIPOP_URL'].blank? and identity_url.include?(ENV['SKIPOP_URL'])
            user = User.create_with_identity_url(identity_url, create_user_params(identity_url, registration))
            if user.valid?
              redirect_to :controller => :portal
            else
              set_error_message_from_user_and_redirect(user)
            end
          else
            set_error_message_not_create_new_user_and_redirect
          end
          return
        end
        reset_session

        user = identifier.user
        session[:user_code] = user.code
        session[:user_name] = user.name
        session[:user_email] = user.user_profile.email
        session[:user_section] = user.user_profile.section

        redirect_to_back_or_root
      else
        set_error_message_form_result_and_redirect(result)
      end
    end
  end

  # -----------------------------------------------
  # over ride open_id_authentication to use OpenID::AX
  def add_simple_registration_fields(open_id_request, fields)
    axreq = OpenID::AX::FetchRequest.new
    requested_attrs = [['http://axschema.org/namePerson', 'fullname'],
                       ['http://axschema.org/company/title', 'job_title'],
                       ['http://axschema.org/contact/email', 'email']]
    requested_attrs.each { |a| axreq.add(OpenID::AX::AttrInfo.new(a[0], a[1], a[2] || false, a[3] || 1)) }
    open_id_request.add_extension(axreq)
    open_id_request.return_to_args['did_ax'] = 'y'
  end

  def complete_open_id_authentication
    params_with_path = params.reject { |key, value| request.path_parameters[key] }
    params_with_path.delete(:format)
    open_id_response = timeout_protection_from_identity_server { open_id_consumer.complete(params_with_path, requested_url) }
    identity_url     = normalize_url(open_id_response.endpoint.claimed_id) if open_id_response.endpoint.claimed_id
    case open_id_response.status
    when OpenID::Consumer::SUCCESS
      yield Result[:successful], identity_url, OpenID::AX::FetchResponse.from_success_response(open_id_response)
    when OpenID::Consumer::CANCEL
      yield Result[:canceled], identity_url, nil
    when OpenID::Consumer::FAILURE
      yield Result[:failed], identity_url, nil
    when OpenID::Consumer::SETUP_NEEDED
      yield Result[:setup_needed], open_id_response.setup_url, nil
    end
  end
  # -----------------------------------------------

  def redirect_to_back_or_root
    return_to = params[:return_to] ? URI.encode(params[:return_to]) : nil
    redirect_to (return_to and !return_to.empty?) ? return_to : root_url
  end

  def create_user_params identity_url, registration
    mappings = {'http://axschema.org/namePerson' => 'name',
      'http://axschema.org/company/title' => 'section',
      'http://axschema.org/contact/email' => 'email' }
    user_attribute = {:code => identity_url.split("/").last}
    mappings.each do |url, column|
      user_attribute[column.to_sym] = registration.data[url][0]
    end
    user_attribute
  end

  def set_error_message_form_result_and_redirect(result)
    error_messages = {
      :missing      => ["OpenIDサーバーが見つかりませんでした。", "正しいOpenID URLを入力してください。"] ,
      :canceled     => ["キャンセルされました。", "このサーバへの認証を確認してください" ],
      :failed       => ["認証に失敗しました。", "" ],
      :setup_needed => ["内部エラーが発生しました。", "管理者に連絡してください。" ]
    }
    set_error_message_and_redirect error_messages[result.instance_variable_get(:@code)], {:controller => :platform, :action => :login}
  end

  def set_error_message_from_user_and_redirect(user)
    set_error_message_and_redirect ["ユーザの登録に失敗しました。", "管理者に連絡してください。<br/>#{user.errors.full_messages}"], :action => :index
  end

  def set_error_message_not_create_new_user_and_redirect
    set_error_message_and_redirect ["そのOpenIDは、登録されていません。", "ログイン後管理画面でOpenID URLを登録後ログインしてください。"], :action => :index
  end

  def set_error_message_and_redirect(message, url)
    flash[:auth_fail_message] = {
      "message" => message.first,
      "detail" => message.last
    }
    redirect_to url
  end
end

