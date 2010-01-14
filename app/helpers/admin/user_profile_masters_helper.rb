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

module Admin::UserProfileMastersHelper
  include HelpIconHelper

  def category_options
    UserProfileMasterCategory.all.collect { |category| [category.name, category.id] }
  end

  def option_values_help_icon_hash_as_json
    h = {}
    UserProfileMaster.input_types.each do |input_type|
      h[input_type] = help_icon_tag(:content => _("Admin::UserProfileMaster|Option values description|#{input_type}"))
    end
    h.to_json
  end

  def option_values_need_hash_as_json
    h = {}
    UserProfileMaster.input_types.each do |val|
      h[val] = UserProfileMaster.input_type_processer_class(val).need_option_values?
    end
    h.to_json
  end
end
