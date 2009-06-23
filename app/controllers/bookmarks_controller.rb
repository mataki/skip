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
<<<<<<< HEAD:app/controllers/bookmarks_controller.rb
=======
    @target_date = Date.today
    if params[:target_date]
      date_array =  params[:target_date].split('-')
      @target_date = Date.new(date_array[0].to_i, date_array[1].to_i, date_array[2].to_i)
    end
    popular_bookmarks = PopularBookmark.find(:all,
                                             :conditions => ["date = ?", @target_date],
                                             :order =>'count DESC' ,
                                             :include => [:bookmark])
    @bookmarks = []
    if popular_bookmarks && popular_bookmarks.size > 0
      popular_bookmarks.each do |popular_bookmark|
        popular_bookmark.bookmark.bookmark_comments.each do |comment|
          if comment.public
            @bookmarks << popular_bookmark.bookmark
            break
          end
        end
      end

      @last_updated = popular_bookmarks.first.created_on.strftime("%Y/%m/%d %H:%M")
    else
      flash.now[:notice] = _('No bookmarks have been registered.')
    end

  end

  # tab_menu
  def search
>>>>>>> for_i18n:app/controllers/bookmarks_controller.rb
    params[:tag_select] ||= "AND"
    params[:type] ||= "all"
    @tags = BookmarkComment.get_popular_tag_words()

    @pages, @bookmarks = paginate(:bookmarks,
                                  :per_page => 20,
                                  :conditions => Bookmark.make_conditions(params),
                                  :include => :bookmark_comments,
<<<<<<< HEAD:app/controllers/bookmarks_controller.rb
                                  :order => get_order_query(params[:sort_type]) )
    flash.now[:notice] = '該当するブックマークはありませんでした。' unless @bookmarks && @bookmarks.size > 0
=======
                                  :order =>order )
    flash.now[:notice] = _('No matching bookmarks found.') unless @bookmarks && @bookmarks.size > 0
>>>>>>> for_i18n:app/controllers/bookmarks_controller.rb
  end

private
  def setup_layout
    @main_menu = @title = _('Bookmarks')

<<<<<<< HEAD:app/controllers/bookmarks_controller.rb
    @tab_menu_source = [ {:label => _('ブックマークを探す'), :options => {:action => 'index'}},
                         {:label => _('ブックマークレット'), :options => {:action => 'setup'}} ]
  end

  def get_order_query(params_order)
    if !(index = Bookmark::SORT_TYPES.map{|a| a.last }.index(params_order)).nil?
      Bookmark::SORT_TYPES[index].last
    else
      Bookmark::SORT_TYPES.first.last
    end
=======
    @tab_menu_source = [ [_('Popularity Rankings'), 'index'],
                         [_('Search'), 'search'],
                         [_('Setup'), 'setup'] ]
>>>>>>> for_i18n:app/controllers/bookmarks_controller.rb
  end
end
