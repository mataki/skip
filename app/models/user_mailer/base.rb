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

class UserMailer::Base < ActionMailer::Base
  helper :initial_settings
  helper :user_mailer

  default_url_options[:host] = Admin::Setting.host_and_port_by_initial_settings_default
  default_url_options[:protocol] = Admin::Setting.protocol_by_initial_settings_default

private
  def self.base64(text, charset="iso-2022-jp", convert=true)
    #Fixme: Japanese dependent
    text = NKF.nkf('-j -m0 --cp932', text) if convert and charset == "iso-2022-jp"
    text = [text].pack('m').delete("\r\n")
    return "=?#{charset}?B?#{text}?="
  end

  def site_url
    root_url
  end

  def contact_addr
    Admin::Setting.contact_addr
  end

  def from
    self.class.base64(Admin::Setting.abbr_app_title) + "<#{contact_addr}>"
  end

  def header
    _('*This email is automatically delivered from the system. Please do not reply.') + "\n" +
    _('This email is a contact from %{sender}') % {:sender => sender} + "\n" +
    ("-" * 66)
  end

  def footer
    contact_description = _('For questions regarding this email, please contact:') % {:sender => sender}
    "----\n*#{contact_description}\n#{contact_addr}\n\n*#{sender}\n#{site_url}"
  end

  def sender
    ERB::Util.html_escape(Admin::Setting.abbr_app_title)
  end

  def smtp_settings
    SkipEmbedded::InitialSettings['mail']['smtp_settings']
  end
end
