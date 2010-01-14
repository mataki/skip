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

module SearchHelper
  def translate_contents_type target_contents, target_icon
    if target_icon[:icon_url]
      image_tag(target_icon[:icon_url], :alt => target_contents )
    else
      icon_tag((target_icon[:icon_type] || 'world_link'), { :margin => true, :title => target_contents} )
    end
  end

  def link_to_search title, query, offset, params
    link_to(title,
            :full_text_query => query,
            :offset => offset,
            :target_contents => params[:target_contents],
            :target_aid => params[:target_aid],
            :searcher => params[:searcher])
  end
end
