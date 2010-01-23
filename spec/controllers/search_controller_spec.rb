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

describe SearchController, "GET /full_text_search" do
  before do
    @current_user = user_login
    @current_user.stub!(:belong_symbols_with_collaboration_apps).and_return({})
    @params = {}
  end
  describe "検索クエリが投げられている場合" do
    before do
      controller.stub!(:make_instance_variables)
      Search.stub!(:new).and_return(mock_search)
    end
    it "Searchの検索を呼ぶこと" do
      Search.should_receive(:new).and_return(mock_search)
      get_full_text_search
    end
    it "リクエストが成功すること" do
      get_full_text_search
      response.should be_success
    end
    it "make_instance_variablesが呼ばれること" do
      controller.should_receive(:make_instance_variables)
      get_full_text_search
    end
  end
  describe "検索クエリが投げられていない場合" do
    it "@error_messageが設定されること" do
      get_full_text_search
      assigns[:error_message].should == Search::NO_QUERY_ERROR_MSG
    end
  end
  def get_full_text_search
    get :full_text_search, @params
  end
  def mock_search(opt = {})
    @mock_search if defined?(@mock_search)
    @mock_search = mock("search", { :invisible_count => 4, :result => mock_result, :error => nil }.merge(opt))
  end
  def mock_result(opt = {})
    @mock_result if defined?(@mock_result)
    @mock_result = mock('result', { }.merge(opt))
  end
end
