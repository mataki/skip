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

module Admin::SettingsHelper
  def settings_label_with_text_field_tag symbolize_key
    label(Admin::Setting.name, symbolize_key) +
    text_field_tag("settings[#{symbolize_key.to_s}]", Admin::Setting.send(symbolize_key.to_s), :id => "setting_#{symbolize_key.to_s}", :size => 60) +
    help_icon_tag(:content => _(Admin::Setting.name + '|' + (symbolize_key.to_s + '_description').humanize))
  end

  def settings_label_with_check_box_tag symbolize_key
    label(Admin::Setting.name, symbolize_key) +
    check_box_tag("settings[#{symbolize_key.to_s}]", "true", Admin::Setting.send("#{symbolize_key.to_s}"), :id => "setting_#{symbolize_key.to_s}") +
    help_icon_tag(:content => _(Admin::Setting.name + '|' + (symbolize_key.to_s + '_description').humanize)) +
    hidden_field_tag("settings[#{symbolize_key.to_s}]", "false")
  end

  def settings_label_with_select_tag symbolize_key, container, selected = nil
    label(Admin::Setting.name, symbolize_key) +
    select_tag("settings[#{symbolize_key.to_s}]", options_for_select(container, selected), :id => "setting_#{symbolize_key.to_s}") +
    help_icon_tag(:content => _(Admin::Setting.name + '|' + (symbolize_key.to_s + '_description').humanize))
  end
end
