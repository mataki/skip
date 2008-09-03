# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008 TIS Inc.
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

require 'rss'
class FeedController < ApplicationController
  #DRY
  def recent_questions
    find_params = BoardEntry.make_conditions(login_user_symbols, {:entry_type=>'DIARY', :recent_day=> 10, :category=>'質問'})
    rss_feed "recent_questions", "みんなからの質問!", board_entry_item_array(find_params)
  end

  def recent_blogs
    find_params = BoardEntry.make_conditions(login_user_symbols, {:entry_type=>'DIARY', :recent_day=> 10, :publication_type => 'public'})
    find_params[:conditions][0] << " and board_entries.title <> 'ユーザー登録しました！'"
    rss_feed "recent_blogs","最近投稿された記事", board_entry_item_array(find_params)
  end

  # 最近のBBSエントリ一覧のRSSを生成するメソッドを動的に生成
  # FIXME recent_bbsと統合したほうがいいかもしれない。mypage_controllerのrecent_bbs_proc辺りも同様の匂いを感じる。
  Group::CATEGORY_KEYS.each do |category|
    define_method( "recent_bbs_#{category.downcase}" ) do
      recent_bbs "recent_bbs#{category.downcase}", category
    end
  end

  # 最近のBBSエントリ一覧のRSSを生成する
  def recent_bbs action_name, category
    description = "最新の掲示板のエントリ（#{Group.category_icon_name(category).last}）"
    find_options = {:exclude_entry_type=>'DIARY', :publication_type => 'public', :recent_day=> 10}
    find_options[:symbols] = Group.gid_by_category[category]
    items = []
    if find_options[:symbols].size > 0
      find_params = BoardEntry.make_conditions(login_user_symbols, find_options)
      items = board_entry_item_array(find_params)
    end
    rss_feed action_name, description, items
  end

  def recent_registed_groups
    description = "最近登録されたグループ"
    groups = Group.find(:all, :order=>"created_on DESC", :conditions=>["created_on > ?" ,Date.today-10], :limit => 10)
    item_arry = []
    groups.map{|group| item_arry << {:type => "group", :title => group.name, :id => group.gid, :date => group.created_on, :contents => group.description } }
    rss_feed "recent_registed_groups", description, item_arry
  end

  def recent_registed_users
    description = "最近登録されたユーザ"
    users = User.find(:all, :order=>"created_on DESC", :conditions=>["created_on > ?" ,Date.today-10], :limit => 10)
    item_arry = []
    users.map{|user| item_arry << {:type => "user", :title => user.name, :id => user.uid, :date => user.created_on, :contents => user.user_profile.self_introduction } }
    rss_feed "recent_registed_users", description, item_arry
  end

  def recent_popular_blogs
    description = "最近の人気記事（質問除く）"
    find_params = BoardEntry.make_conditions(login_user_symbols, {:publication_type => 'public'})
    find_params[:conditions][0] << " and board_entries.category not like ?"
    find_params[:conditions] << '%[質問]%'
    find_params[:conditions][0] << " and last_updated > ?"
    find_params[:conditions] << Date.today-10
    order = "board_entry_points.today_access_count DESC, board_entry_points.access_count DESC, board_entries.last_updated DESC, board_entries.id DESC"
    rss_feed "recent_popular_blogs", description, board_entry_item_array(find_params, order)
  end

  def message_for_you
    description = "あなたへの連絡"
    find_params = BoardEntry.make_conditions login_user_symbols, { :category=>'連絡' }
    user_reading_condition find_params
    rss_feed "message_for_you", description, board_entry_item_array(find_params)
  end

  def your_commented_blogs
    description = "コメントの行方"
    find_params = BoardEntry.make_conditions(login_user_symbols)
    user_id = session[:user_id]
    find_params[:conditions][0] << "and board_entry_comments.user_id = ? and user_readings.read = ? and user_readings.user_id = ?"
    find_params[:conditions] << user_id << false << user_id
    find_params[:include] << :user_readings << :board_entry_comment
    rss_feed "your_commented_blogs", description, board_entry_item_array(find_params)
  end

  def your_bookmarked_blogs
    description = "ブクマの行方"
    bookmarks = Bookmark.find(:all,
                              :conditions => ["bookmark_comments.user_id = ? and bookmarks.url like '/page/%'", session[:user_id]],
                              :include => [:bookmark_comments])
    ids = []
    bookmarks.each do |bookmark|
      ids << bookmark.url.gsub(/\/page\//, "")
    end
    find_params = BoardEntry.make_conditions(login_user_symbols)
    find_params[:conditions][0] << " and board_entries.id in (?) and user_readings.read = ? and user_readings.user_id = ?"
    find_params[:conditions] << ids << false << session[:user_id]
    find_params[:include] << :user_readings
    rss_feed "your_bookmarked_blogs", description, board_entry_item_array(find_params)
  end

  def participate_group_bbs
    description = "参加グループ"
    find_params = BoardEntry.make_conditions login_user_symbols, { :symbols => login_user_groups }
    user_reading_condition find_params
    rss_feed "participate_group_bbs", description, board_entry_item_array(find_params)
  end

  def user_antenna
    antenna = Antenna.find(params[:antenna_id])
    symbols, keyword = antenna.get_search_conditions
    find_params = BoardEntry.make_conditions(login_user_symbols, :symbols => symbols, :keyword => keyword)
    user_reading_condition find_params
    rss_feed "user_antenna", antenna.name, board_entry_item_array(find_params)
  end

private
  def rss_feed action_name, description,item_arry
    server_addr = root_url
    rss = RSS::Maker.make("1.0") do |maker|
      maker.channel.about = url_for(:controller => "feed", :action => action_name)
      maker.channel.title = "マイページ/" + description
      maker.channel.link = server_addr
      maker.channel.description = description
      item_arry.each do |item_value|
        item = maker.items.new_item
        item.title = item_value[:title]+"　コメント数:("+item_value[:comment_count].to_s+")"
        item.link = ""
        item.link <<  server_addr
        case item_value[:type]
          when "page"
          item.link << 'page/'
          when "user"
          item.link << 'user/'
          when "group"
          item.link << 'group/'
        end
        if item_value[:type] == "page"
          item.link << item_value[:id].to_s
        else
          item.link << item_value[:id]
        end
        item.description = item_value[:contents]
        item.date = item_value[:date]
        item.dc_creator = item_value[:author] if item_value[:author]
      end
      maker.items.do_sort = true
      maker.items.max_size = 10
    end
    headers["Content-type"] = 'application/xml; charset=UTF-8'
    render :text => rss.to_s, :layout => false
  end

  def board_entry_item_array find_params, order = "last_updated DESC,board_entries.id DESC"
    pages = BoardEntry.find(:all,
                           :order => order,
                           :conditions=> find_params[:conditions],
                           :include => find_params[:include] | [ :user, :state ])
    item_arry = []
    pages.map{|page| item_arry << {:type => "page", :title => page.title, :id => page.id, :date => page.last_updated, :contents => page.contents, :author => page.user.name, :comment_count => page.board_entry_comments_count}  }
    item_arry
  end

  def user_reading_condition params
    params[:conditions][0] << " and user_readings.read = ? and user_readings.user_id = ?"
    params[:conditions] << false << session[:user_id]
    params[:include] << :user_readings
  end
end
