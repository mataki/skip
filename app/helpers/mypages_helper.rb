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

module MypagesHelper

  # タイトルバーの表示
  def show_title_bar(icon, label, all_url = nil)
    content_tag(:div, :style => "position: relative; _width: 100%;") do
      title_tag = content_tag(:h2, :class => 'topix_title'){ icon_tag(icon) + link_to_unless(all_url.blank?, h(label), all_url) }
    end
  end
end
