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

class SearchController < ApplicationController

  #全文検索
  def full_text_search
    @main_menu = @title = _('Full-text Search')

    params[:target_aid] ||= "all"
    params[:query] = params[:full_text_query] unless params[:full_text_query].blank?
    params[:per_page] = 10
    params[:offset] ||= 0

    search = Search.new(params, current_user.belong_symbols_with_collaboration_apps)
    if search.error.blank?
      # TODO: インスタンス変数に代入することなく@searchで画面表示
      @invisible_count = search.invisible_count
      make_instance_variables search.result
    else
      # Searchクラスのメッセージの国際化
      N_("Please input search query.")
      N_("Access denied by search node. Please contact system owner.")
      @error_message = search.error
    end
  end

private
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
