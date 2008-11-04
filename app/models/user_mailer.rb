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
  def sent_contact(recipient, user_name, entry_url, entry_title)
    if recipient.include? ","
      @bcc        = recipient
    else
      @recipients = recipient
    end
    @subject    = UserMailer.base64("[#{Admin::Setting.abbr_app_title}] #{user_name}さんから連絡がきています")
    @from       = @@from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:name=>user_name, :entry_url=>entry_url, :entry_title => entry_title, :footer => @@footer}
  end

  def sent_message(recipient, link_url, message ,message_manage_url)
    @recipients = recipient
    @subject    = UserMailer.base64("[#{Admin::Setting.abbr_app_title}] #{message}")
    @from       = @@from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:link_url=>link_url, :message => message, :message_manage_url => message_manage_url, :footer => @@footer}
  end

  def sent_signup_confirm(recipient, confirm_url)
    @recipients = recipient
    @subject    = UserMailer.base64("[#{Admin::Setting.abbr_app_title}] ユーザ登録の確認メールです")
    @from       = @@from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:confirm_url=>confirm_url, :footer => @@footer}
  end

  def sent_apply_email_confirm(recipient, confirm_url)
    @recipients = recipient
    @subject    = UserMailer.base64("[#{Admin::Setting.abbr_app_title}] メールアドレス変更の確認メールです")
    @from       = @@from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:confirm_url=>confirm_url, :footer => @@footer}
  end

  def sent_forgot_password(recipient, reset_password_url)
    @recipients = recipient
    @subject    = UserMailer.base64("[#{Admin::Setting.abbr_app_title}] パスワードリセットの確認メールです")
    @from       = @@from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:reset_password_url => reset_password_url, :footer => @@footer}
  end

  def sent_forgot_login_id(recipient, login_id)
    @recipients = recipient
    @subject    = UserMailer.base64("[#{Admin::Setting.abbr_app_title}] ログインIDのお知らせです")
    @from       = @@from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:login_id => login_id, :footer => @@footer}
  end

  def sent_activate(recipient, signup_url)
    @recipients = recipient
    @subject    = UserMailer.base64("[#{Admin::Setting.abbr_app_title}] " + _('ユーザ登録の確認メールです'))
    @from       = @@from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:signup_url => signup_url, :footer => @@footer}
  end

private
  def self.base64(text, charset="iso-2022-jp", convert=true)
    text = NKF.nkf('-j -m0 --cp932', text) if convert and charset == "iso-2022-jp"
    text = [text].pack('m').delete("\r\n")
    return "=?#{charset}?B?#{text}?="
  end

  @@site_url = "#{Admin::Setting.protocol_by_initial_settings_default}#{Admin::Setting.host_and_port_by_initial_settings_default}/"
  @@system_mail_addr = Admin::Setting.contact_addr
  @@from = UserMailer.base64(Admin::Setting.abbr_app_title) + "<#{@@system_mail_addr}>"
  @@footer = "----\n#{@@system_mail_addr}\n#{@@site_url}"
end
