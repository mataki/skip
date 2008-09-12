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

class SymbolController < ApplicationController

  # ajax_action
  def get_name_by_symbol
    item = Symbol.get_item_by_symbol(params[:symbol])
    render :text => item ? item.name : '対象が見つかりません。'
  end

  # ajax_action
  def auto_complete_for_item_search
    symbol = params[:q] #symbol又は名前(ユーザ、グループ)

    if params[:q] =~ /\A(uid:|gid:).*/
      @items = get_items_by_like_query_symbol(symbol) || []
    else
      @items = get_items_by_like_query_name(symbol) || []
    end
    if @items.empty?
      render :nothing => true
    else
      result = ''
      @items.each do |item|
        result << "#{item.symbol}|#{item.name}\n"
      end
      render :text => result
    end
  end

private
  # symbolの一部からオブジェクトの配列を取り出す(ログインユーザに公開されているもののみ)
  def get_items_by_like_query_symbol symbol
    symbol_type, symbol_id = Symbol.split_symbol symbol
    case symbol_type
    when "uid"
      return  User.find(:all, :conditions =>["user_uids.uid LIKE ?", SkipUtil.to_lqs(symbol_id)], :include => [:user_uids])
    when "gid"
      return  Group.find(:all, :conditions =>["gid LIKE ?", SkipUtil.to_lqs(symbol_id)])
    end
  end

  # symbolの一部からオブジェクトの配列を取り出す(ログインユーザに公開されているもののみ)
  def get_items_by_like_query_name name
    items = User.find(:all, :conditions =>["name LIKE ?", SkipUtil.to_lqs(name)])
    items.concat Group.find(:all, :conditions =>["name LIKE ?", SkipUtil.to_lqs(name)])
    return items
  end

end
