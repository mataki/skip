# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008  TIS Inc.
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

module ServicesHelper
  def draw_menu_links links
    result = ""
    links.each do |service|
      point = icon_tag(service[:icon]) + " "
      result << %!'<div style="background-color: #cfdce5;">#{service[:title]}</div>',!
      service[:links].each do |link|
        result << %!'#{link_to(point + link[:title], link[:url], :target => "_blank")}<br/>',!
      end
    end
    result
  end
end
