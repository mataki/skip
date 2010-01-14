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

class PopularBookmark < ActiveRecord::Base
  belongs_to :bookmark, :include => :bookmark_comments

  def tags_as_string
    tags = []
    bookmark.bookmark_comments.each do |comment|
      tags.concat(Tag.split_tags(comment.tags))
    end
    tag_str =  tags.uniq.join('][')
    return tags.size > 0 ? "[#{tag_str}]" :""
  end

end
