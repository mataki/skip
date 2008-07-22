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

class BookmarksController < ApplicationController
  before_filter :setup_layout

  # tab_menu
  def index
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
      flash.now[:notice] = '現在ブックマークは登録されていません。'
    end

  end

  # tab_menu
  def search
    params[:tag_select] ||= "AND"
    params[:type] ||= "all"
    @sort_types = Bookmark.get_sort_types
    @tags = BookmarkComment.get_popular_tag_words()

    order = params[:sort_type] || "bookmarks.created_on DESC" #ソート順(初期値は登録日降順)
    @pages, @bookmarks = paginate(:bookmarks,
                                  :per_page => 20,
                                  :conditions => Bookmark.make_conditions(params),
                                  :include => :bookmark_comments,
                                  :order =>order )
    flash.now[:notice] = '該当するブックマークはありませんでした。' unless @bookmarks && @bookmarks.size > 0
  end

private
  def setup_layout
    @main_menu = @title = 'ブックマーク'

    @tab_menu_source = [ ['トップ', 'index'],
                         ['検索', 'search'],
                         ['セットアップ', 'setup'] ]
  end
end
