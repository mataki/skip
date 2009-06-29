# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
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
  before_filter :setup_layout

  def index
    params[:tag_select] ||= "AND"
    params[:type] ||= "all"
    @tags = BookmarkComment.get_popular_tag_words()

    @pages, @bookmarks = paginate(:bookmarks,
                                  :per_page => 20,
                                  :conditions => Bookmark.make_conditions(params),
                                  :include => :bookmark_comments,
                                  :order => get_order_query(params[:sort_type]) )
    flash.now[:notice] = _('No matching bookmarks found') unless @bookmarks && @bookmarks.size > 0
  end

private
  def setup_layout
    @main_menu = @title = _('Bookmarks')

    @tab_menu_source = [ {:label => _('Search for Bookmarks'), :options => {:action => 'index'}},
                         {:label => _('Setup'), :options => {:action => 'setup'}} ]
  end

  def get_order_query(params_order)
    if !(index = Bookmark::SORT_TYPES.map{|a| a.last }.index(params_order)).nil?
      Bookmark::SORT_TYPES[index].last
    else
      Bookmark::SORT_TYPES.first.last
    end
  end
end
