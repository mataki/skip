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

class BookmarksController < ApplicationController
  before_filter :require_bookmark_enabled
  before_filter :setup_layout

  def index
    params[:tag_select] ||= "AND"
    params[:type] ||= "all"
    @tags = BookmarkComment.get_popular_tag_words()

    @bookmarks = Bookmark.scoped(
      :conditions => Bookmark.make_conditions(params),
      :include => :bookmark_comments,
      :order => get_order_query(params[:sort_type])
    ).paginate(:page => params[:page], :per_page => 25)

    flash.now[:notice] = _('No matching bookmarks found') if @bookmarks.empty?
  end

private
  def setup_layout
    @main_menu = @title = _('Bookmarks')
  end

  def get_order_query(params_order)
    if !(index = Bookmark::SORT_TYPES.map{|a| a.first }.index(params_order)).nil?
      Bookmark::SORT_TYPES[index].last
    else
      Bookmark::SORT_TYPES.first.last
    end
  end
end
