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

class SymbolController < ApplicationController

  # ajax_action
  def get_name_by_symbol
    item = Symbol.get_item_by_symbol(params[:symbol])
    render :text => item ? item.name : _('Target not found.')
  end

  # ajax_action
  def auto_complete_for_item_search
    items = Symbol.items_by_partial_match_symbol_or_name(params[:q])
    if items.empty?
      render :nothing => true
    else
      render :text => items.map{|item| ERB::Util.h("#{item.symbol}|#{item.name}")}.join("\n")
    end
  end
end
