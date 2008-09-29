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
end
