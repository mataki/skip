# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2010 TIS Inc.
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

module InitialSettingsHelper
  def login_mode?(mode)
    case mode
    when :password
      return SkipEmbedded::InitialSettings['login_mode'] == 'password'
    when :free_rp
      return (SkipEmbedded::InitialSettings['login_mode'] == 'rp' and SkipEmbedded::InitialSettings['fixed_op_url'].blank?)
    when :fixed_rp
      return (SkipEmbedded::InitialSettings['login_mode'] == 'rp' and !SkipEmbedded::InitialSettings['fixed_op_url'].blank?)
    else
      return false
    end
  end

  def user_name_mode?(mode)
    case mode
    when :name
      return SkipEmbedded::InitialSettings['username_use_setting']
    when :code
      return SkipEmbedded::InitialSettings['usercode_dips_setting']
    end
    false
  end

  def user_name_mode_label
    label = []
    label << Admin::Setting.login_account if user_name_mode?(:code)
    label << _('user name') if user_name_mode?(:name)
    label.join("/")
  end

  def enable_activate?
    login_mode?(:password) && !Admin::Setting.stop_new_user && SkipEmbedded::InitialSettings['mail']['show_mail_function']
  end

  def enable_signup?
    login_mode?(:password)
  end

  def enable_forgot_password?
    login_mode?(:password) && SkipEmbedded::InitialSettings['mail']['show_mail_function']
  end

  def enable_forgot_openid?
    login_mode?(:free_rp) && SkipEmbedded::InitialSettings['mail']['show_mail_function']
  end
end
