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

module TagsHelper
  def toggle_links links, show_max = 3
    show_links_as_s = links.slice!(0..show_max - 1).join(',&nbsp;')
    hide_links_as_s =
      if links.size > 0
        str = link_to(icon_tag('bullet_toggle_plus'), '#', :class => 'tag_open')
        str << content_tag(:span, :class => 'invisible') do
          links.join(',&nbsp;') + link_to(icon_tag('bullet_toggle_minus'), '#', :class => 'tag_close')
        end
      end || ''
    show_links_as_s + '&nbsp;' + hide_links_as_s
  end
end
