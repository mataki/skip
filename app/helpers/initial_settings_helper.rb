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

module InitialSettingsHelper
  def login_mode?(mode)
    case mode
    when :password
      return INITIAL_SETTINGS['login_mode'] == 'password'
    when :free_rp
      return (INITIAL_SETTINGS['login_mode'] == 'rp' and INITIAL_SETTINGS['fixed_op_url'].blank?)
    when :fixed_rp
      return (INITIAL_SETTINGS['login_mode'] == 'rp' and !INITIAL_SETTINGS['fixed_op_url'].blank?)
    else
      return false
    end
  end

  def user_name_mode?(mode)
    case mode
    when :name
      return INITIAL_SETTINGS['username_use_setting']
    when :code
      return INITIAL_SETTINGS['usercode_dips_setting']
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
    login_mode?(:password) && !Admin::Setting.stop_new_user && Admin::Setting.mail_function_setting
  end

  def enable_signup?
    login_mode?(:password)
  end

  def enable_forgot_password?
    login_mode?(:password) && Admin::Setting.mail_function_setting
  end

  def enable_forgot_openid?
    login_mode?(:free_rp) && Admin::Setting.mail_function_setting
  end
end
