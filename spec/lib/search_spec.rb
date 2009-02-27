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

require File.dirname(__FILE__) + '/../spec_helper'

describe Search, "#initialize" do
  describe "検索クエリが入力されていない場合" do
    it "エラーが投げられること" do
      result = Search.new({ :query => "" } ,['sid:allusers'])
      result.error.should == "please input query"
    end
  end
  describe "検索クエリが入力されている場合" do
    before do
      @query = { :query => "test" }
      @symbols = ["sid:allusers"]
    end
    describe "HyperEstraierで検索結果がみつかった場合" do
      before do
        element = { :publication_symbols => "uid:a_user" }
        @result = mock('est_result', :error => nil, :offset => 0, :per_page => 10, :result_hash => {:elements => [{ :publication_symbols => "uid:a_user" }]})
        Search::HyperEstraier.stub!(:new).and_return(@result)
        Search.stub!(:remove_invisible_element).and_return([])
      end
      it "paramsをHyperEstraierに引き渡すこと" do
        Search::HyperEstraier.should_receive(:new).and_return(@result)
        Search.new(@query, @symbols)
      end
      it "閲覧権限のチェックを行なうこと" do
        Search.should_receive(:remove_invisible_element).and_return([])
        Search.new(@query, @symbols)
      end
      it "@invisible_countが設定されること" do
        result = Search.new(@query, @symbols)
        result.invisible_count.should == 1
      end
      it "結果のelementsに権限チェックを行なったelementsが入っていること" do
        result = Search.new(@query, @symbols)
        result.result[:elements].should == []
      end
    end
    describe "検索でエラーがあった場合" do
      it "エラーが設定されること" do
        @result = mock('est_result', :error => "error")
        Search::HyperEstraier.stub!(:new).and_return(@result)
        result = Search.new(@query, @symbols)
        result.error.should == "error"
      end
    end
  end
end

describe Search, ".remove_invisible_element" do
  before do
    @publication_symbols = ["sid:allusers", "uid:a_user"]
  end
  describe "ユーザの閲覧権限に入っている要素があった場合" do
    it "結果に含まれること" do
      elements = [{ :hoge => "fuga"}, {:a => "a", :publication_symbols => "uid:b_user,uid:a_user"}]
      result = Search.remove_invisible_element elements, @publication_symbols
      result.should be_include(elements.last)
    end
  end
  describe "ユーザの閲覧権限に含まれてない要素の場合" do
    it "結果に含まれないこと" do
      elements = [{:a => "a", :publication_symbols => "uid:b_user,uid:c_user"}]
      result = Search.remove_invisible_element elements, @publication_symbols
      result.should_not be_include(elements.first)
      result.should be_blank
    end
  end
end

describe Search, ".get_metadata" do
  describe "メタ情報が取得される場合" do
    before do
      INITIAL_SETTINGS["search_apps"] = { "SKIP" => { "meta" => "/hoge/fuga/meta", "cache" => "localhost:3000/app_cache" } }

      File.stub!(:file?).and_return(true)
      File.stub!(:open)
      YAML.stub!(:load).and_return({ "title" => "meta title", "publication_symbols" => "sid:allusers", "contents_type" => "meta", "link_url" => "http://localhost:3000/meta"})
    end
    it "メタ情報が返ってくること" do
      result = Search.get_metadata "contents", "http://localhost:3000/app_cache/hoge/fuga", "title"
      result.should == {:contents_type=>"meta", :publication_symbols=>"sid:allusers", :title=>"meta title", :contents=>"contents", :link_url=>"http://localhost:3000/meta"}
    end
    it "メタ情報に数字のみのvalueがある場合 メタ情報が返ってくること" do
      YAML.stub!(:load).and_return({ "title" => 1111, "publication_symbols" => "sid:allusers", "contents_type" => "meta", "link_url" => "http://localhost:3000/meta"})
      result = Search.get_metadata "contents", "http://localhost:3000/app_cache/hoge/fuga", "title"
      result.should == {:contents_type=>"meta", :publication_symbols=>"sid:allusers", :title=>"1111", :contents=>"contents", :link_url=>"http://localhost:3000/meta"}
    end
  end
end

