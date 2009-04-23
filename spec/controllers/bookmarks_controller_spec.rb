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

require File.dirname(__FILE__) + '/../spec_helper'

describe BookmarksController, "GET index" do
  before do
    user_login
  end
  describe "sort_typeに不正なパラメータが送られた場合" do
    it "SQLインジェクションが起こらないこと" do
      lambda do
        get :index, :sort_type => "created_on; SELECT * from users"
      end.should_not raise_error
    end
  end
  describe "sort_typeに正しいパラメータが送られた場合" do
    it "正しく検索されること" do
      lambda do
        get :index, :sort_type => "bookmarks.updated_on DESC"
      end.should_not raise_error
      response.should be_success
    end
  end
end

describe BookmarksController, "#get_order_query" do
  describe "パラメータが規定の値の場合" do
    it "パラメータに該当する値を返すこと" do
      Bookmark::SORT_TYPES.each do |sort_type|
        controller.send(:get_order_query, sort_type.last).should == sort_type.last
      end
    end
  end
  describe "パラメータが規定の値以外の場合" do
    it "デフォルト値を返すこと" do
      controller.send(:get_order_query, "created_on; SELECT * from users").should == Bookmark::SORT_TYPES.first.last
    end
  end
end
