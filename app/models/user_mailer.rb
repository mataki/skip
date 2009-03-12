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

class UserMailer < ActionMailer::Base
  helper :initial_settings
  def sent_contact(recipient, user_name, entry_url, entry_title)
    if recipient.include? ","
      @bcc        = recipient
    else
      @recipients = recipient
    end
    @subject    = UserMailer.base64("[#{Admin::Setting.abbr_app_title}] #{user_name}さんから連絡がきています")
    @from       = from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:name => user_name, :entry_url => entry_url, :entry_title => entry_title, :header => header, :footer => footer}
  end

  def sent_message(recipient, link_url, message ,message_manage_url)
    @recipients = recipient
    @subject    = UserMailer.base64("[#{Admin::Setting.abbr_app_title}] #{message}")
    @from       = from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:link_url => link_url, :message => message, :message_manage_url => message_manage_url, :header => header, :footer => footer}
  end

  def sent_signup_confirm(recipient, login_id, login_url)
    @recipients = recipient
    @subject    = UserMailer.base64("[#{Admin::Setting.abbr_app_title}] ユーザ登録が完了しました")
    @from       = from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:login_id => login_id, :login_url => login_url, :header => header, :footer => footer}
  end

  def sent_apply_email_confirm(recipient, confirm_url)
    @recipients = recipient
    @subject    = UserMailer.base64("[#{Admin::Setting.abbr_app_title}] メールアドレス変更の確認メールです")
    @from       = from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:confirm_url => confirm_url, :header => header, :footer => footer}
  end

  def sent_forgot_password(recipient, reset_password_url)
    @recipients = recipient
    @subject    = UserMailer.base64("[#{Admin::Setting.abbr_app_title}] パスワード再設定のメールです")
    @from       = from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:reset_password_url => reset_password_url, :header => header, :footer => footer}
  end

  def sent_forgot_openid(recipient, reset_openid_url)
    @recipients = recipient
    @subject    = UserMailer.base64("[#{Admin::Setting.abbr_app_title}] OpenIDの再設定のメールです")
    @from       = from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:reset_openid_url => reset_openid_url, :header => header, :footer => footer}
  end

  def sent_activate(recipient, signup_url)
    @recipients = recipient
    @subject    = UserMailer.base64("[#{Admin::Setting.abbr_app_title}] " + _('利用開始確認メールです'))
    @from       = from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:signup_url => signup_url, :site_url => site_url, :header => header, :footer => footer}
  end

  def sent_cleaning_notification(recipient)
    @recipients = recipient
    @subject    = UserMailer.base64("[#{Admin::Setting.abbr_app_title}] " + _('ユーザのクリーニングは行ってますか?'))
    @from       = from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:header => header, :footer => footer}
  end

private
  def self.base64(text, charset="iso-2022-jp", convert=true)
    text = NKF.nkf('-j -m0 --cp932', text) if convert and charset == "iso-2022-jp"
    text = [text].pack('m').delete("\r\n")
    return "=?#{charset}?B?#{text}?="
  end

  def site_url
    root_url(:protocol => Admin::Setting.protocol_by_initial_settings_default, :host => Admin::Setting.host_and_port_by_initial_settings_default)
  end

  def contact_addr
    Admin::Setting.contact_addr
  end

  def from
    UserMailer.base64(Admin::Setting.abbr_app_title) + "<#{contact_addr}>"
  end

  def header
    _('※このメールはシステムから自動配信されています。返信しないで下さい。') + "\n\n" +
    _('%{sender}からのご連絡です。') % {:sender => sender}
  end

  def footer
    contact_description = _('本メールに関するお問い合わせはこちらへ') % {:sender => sender}
    "----\n*#{contact_description}\n#{contact_addr}\n\n*#{sender}\n#{site_url}"
  end

  def sender
    ERB::Util.html_escape(Admin::Setting.abbr_app_title)
  end

  def smtp_settings
    { :address => Admin::Setting.smtp_settings_address,
      :port => Admin::Setting.smtp_settings_port,
      :domain => Admin::Setting.smtp_settings_domain,
      :user_name => Admin::Setting.smtp_settings_user_name.blank? ? nil : Admin::Setting.smtp_settings_user_name,
      :password => Admin::Setting.smtp_settings_password.blank? ? nil : Admin::Setting.smtp_settings_password,
      :authentication => Admin::Setting.smtp_settings_authentication.blank? ? nil : Admin::Setting.smtp_settings_authentication }
  end

  def delivery_method
    Admin::Setting.mail_function_setting ? :smtp : :test
  end
end
