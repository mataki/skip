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

require File.dirname(__FILE__) + '/../spec_helper'

describe SymbolController, "GET auto_complete_for_item_search" do
  before do
    user_login
    @items = (1..2).map{|i| mock('item', "symbol" => "symbol#{i}", "name" => "name#{i}")}
    @items << mock('item', "symbol" => "hoge", "name" => "<script/>aaa")
  end
  describe "uid:xxxxと入力した場合" do
    before do
      Symbol.should_receive(:items_by_partial_match_symbol_or_name).and_return(@items)
      get :auto_complete_for_item_search, :q => "uid:xxx"
    end
    it "アイテムが|で繋がれて返ること" do
      response.body.should be_include("symbol1|name1\n")
    end
    it "サニタイズされること" do
      response.body.should_not be_include("<script>")
    end
  end
end
