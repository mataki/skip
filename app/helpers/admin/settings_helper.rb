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

module Admin::SettingsHelper
  def settings_label_with_text_field_tag symbolize_key, options = {}
    options = {:id => "setting_#{symbolize_key}"}.merge(options)
    label(Admin::Setting.name, symbolize_key) +
      text_field_tag("settings[#{symbolize_key}]", current_setting(symbolize_key), options) +
      help_icon_tag(:content => s_(Admin::Setting.name + '|' + (symbolize_key.to_s + '_description').humanize))
  end

  def settings_label_with_check_box_tag symbolize_key
    label(Admin::Setting.name, symbolize_key) +
      hidden_field_tag("settings[#{symbolize_key}]", "false") +
      check_box_tag("settings[#{symbolize_key}]", "true", current_setting(symbolize_key), :id => "setting_#{symbolize_key}") +
      help_icon_tag(:content => s_(Admin::Setting.name + '|' + (symbolize_key.to_s + '_description').humanize))
  end

  def settings_label_with_select_tag symbolize_key, container, selected = nil
    label(Admin::Setting.name, symbolize_key) +
      select_tag("settings[#{symbolize_key}]", options_for_select(container, selected || current_setting(symbolize_key)), :id => "setting_#{symbolize_key}") +
      help_icon_tag(:content => s_(Admin::Setting.name + '|' + (symbolize_key.to_s + '_description').humanize))
  end

  def settings_label_with_password_field_tag symbolize_key, options = {}
    options = {:id => "setting_#{symbolize_key}"}.merge(options)
    label(Admin::Setting.name, symbolize_key) +
      password_field_tag("settings[#{symbolize_key}]", Admin::Setting.send(symbolize_key.to_s), options) +
      help_icon_tag(:content => s_(Admin::Setting.name + '|' + (symbolize_key.to_s + '_description').humanize))
  end

  def smtp_authentication_container
    [''] + Admin::Setting::SMTP_AUTHENTICATIONS
  end

  def password_strength_container
    returning container = [] do
      Admin::Setting::PASSWORD_STRENGTH_VALUES.each do |value|
        container.push [s_(Admin::Setting.name + '|Password strength|' + value), value]
      end
    end
  end

  def enable_any_embed?
    Admin::Setting.youtube || Admin::Setting.slideshare || Admin::Setting.googlemap
  end
end

