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

require "rexml/document"
require "open-uri"

class SearchController < ApplicationController

  # tab_menu
  def entry_search
    @main_menu = @title = '記事'
    @tab_menu_source = [ {:label => _('記事を探す'), :options => {:action => 'entry_search'}} ]

    params[:tag_select] ||= "AND"
    find_params = BoardEntry.make_conditions(login_user_symbols, {:keyword =>params[:keyword],
                                               :tag_words => params[:tag_words],
                                               :tag_select => params[:tag_select]})

    if params[:user] or params[:group]
      find_params[:conditions][0] << " and ("
    end

    additional_state = ""
    if params[:user]
      additional_state << "board_entries.entry_type = 'DIARY'"
    end
    if params[:group]
      additional_state << " or " unless additional_state.empty?
      additional_state << "board_entries.entry_type = 'GROUP_BBS'"
    end

    find_params[:conditions][0] << additional_state

    if params[:user] or params[:group]
      find_params[:conditions][0] << " ) "
    end

    @pages, @board_entries = paginate(:board_entry,
                                      :per_page => 8,
                                      :order => "last_updated DESC",
                                      :conditions => find_params[:conditions],
                                      :include => find_params[:include] | [ :user, :state ])
    unless @board_entries && @board_entries.size > 0
      flash.now[:notice] = '該当するデータはありませんでした。'
    end

    @symbol2name_hash = BoardEntry.get_symbol2name_hash @board_entries
    @tags = BoardEntry.get_popular_tag_words
  end

  # tab_menu
  def share_file_search
    @main_menu = @title = 'ファイル'
    @tab_menu_source = [ {:label => _('ファイルを探す'), :options => {:action => 'share_file_search'}} ]

    @tags = ShareFile.get_popular_tag_words

    params[:tag_select] ||= "AND"
    params[:sort_type] ||= "date"
    params_hash = { :category => params[:category],
                    :keyword => params[:keyword],
                    :tag_words => params[:tag_words],
                    :tag_select => params[:tag_select] }
    find_params = ShareFile.make_conditions(login_user_symbols, params_hash)
    order_by = (params[:sort_type] == "date" ? "date desc" : "file_name")

    @pages, @share_files = paginate(:share_files,
                                    :conditions => find_params[:conditions],
                                    :include => find_params[:include],
                                    :order => order_by,
                                    :per_page => 10)
    unless @share_files && @share_files.size > 0
      if params[:commit] || params[:category]
        flash.now[:notice] = '該当するファイルはありませんでした。'
      else
        flash.now[:notice] = '現在公開されているファイルはありません。'
      end
    end
  end

  #全文検索
  def full_text_search
    @main_menu = @title = '全文検索'

    params[:query] = params[:full_text_query] unless params[:full_text_query].blank?
    params[:target_contents] ||= 'all'
    params[:target_aid] ||= 'all'
    params[:per_page] = 10
    params[:offset] ||= 0

    begin
      search = Search.new(params, belong_symbols(session[:user_code]))

      @invisible_count = search.invisible_count

      make_instance_variables search.result
    rescue Search::SearchError => e
      e.backtrace.each {|msg| logger.error msg }
      @error_message = e.message
    end
  end

private
  # 所属情報を取得するためのメソッド
  # user_codeを渡すと所属情報と設定のアプリの所属情報を取得する
  def belong_symbols user_code
    symbols = ['sid:allusers'] + login_user_symbols

    unless INITIAL_SETTINGS['belong_info_apps'].blank?
      INITIAL_SETTINGS['belong_info_apps'].each do |app_name, setting|
        join_info = MemcacheUtil.get(user_code, app_name, setting[:api])
        join_info[setting[:hash_key]].each{ |key, value| symbols << "#{setting[:prefix]}:#{key.to_s}" } if join_info
      end
    end
    symbols
  end

  # 全文検索の各画面用に@変数を作成するメソッド
  def make_instance_variables search_result
    @result_lines = search_result[:elements]
    @max_count = search_result[:header][:count]
    @per_page = search_result[:header][:per_page]

    prev_offset = search_result[:header][:prev].empty? ? nil : search_result[:header][:start_count] - @per_page - 1
    next_offset = search_result[:header][:next].empty? ? nil : search_result[:header][:start_count] + @per_page - 1

    @result_info_locals = {
      :query => params[:query],
      :prev_offset => prev_offset,
      :next_offset => next_offset,
      :max_count => @max_count,
      :start_count => search_result[:header][:start_count],
      :end_count => search_result[:header][:end_count]
    }

    range_max = 9 # 今のページから前後何ページ分の範囲をooooooで表現するか
    current_page = search_result[:header][:start_count] / @per_page + 1 # 何ページ目か
    total_page_count = (@max_count - 1) / @per_page + 1 # 全部で何ページあるか
    start_index = current_page - range_max
    start_index = 1 if start_index <= 0
    end_index = current_page + range_max
    end_index = total_page_count if end_index > total_page_count
    end_index = 100 if end_index > 100

    @page_navi_locals = {
      :query => params["query"],
      :prev_offset => prev_offset,
      :next_offset => next_offset,
      :per_page => @per_page,
      :current_page => current_page,
      :start_index => start_index,
      :end_index => end_index
    }
  end

end
