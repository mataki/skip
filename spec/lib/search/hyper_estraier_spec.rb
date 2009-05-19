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

require File.dirname(__FILE__) + '/../../spec_helper'

describe Search::HyperEstraier, "#initialize" do
  before do
    @node = mock('node')
    @node.stub!(:search)
    Search::HyperEstraier.stub!(:get_node).and_return(@node)
  end
  it "per_page, offsetを設定すること" do
    he = Search::HyperEstraier.new({})
    he.per_page.should == 10
    he.offset.should == 0
  end
  it "get_conditionにparamsが正しくわたること" do
    Search::HyperEstraier.should_receive(:get_condition).with("query", "target_aid", "target_contents")
    Search::HyperEstraier.new :query => "query", :target_aid => "target_aid", :target_contents => "target_contents"
  end
  describe "検索結果が返ってきたとき" do
    before do
      @nres = mock('nres', :hint => "5")
      @node.stub!(:search).and_return(@nres)
      Search::HyperEstraier.stub!(:get_result_hash_header).and_return("result_header")
      Search::HyperEstraier.stub!(:get_result_hash_elements).and_return("result_elements")
    end
    it "result_hashが登録されていること" do
      result = Search::HyperEstraier.new({})
      result.result_hash[:header].should == "result_header"
      result.result_hash[:elements].should == "result_elements"
    end
    it "@errorが設定されていないこと" do

    end
  end
  describe "検索ノードにアクセスできないとき" do
    it "@errorにメッセージが登録されていること" do
      result = Search::HyperEstraier.new({})
      result.error.should == Search::HyperEstraier::ACCESS_DENIED_ERROR_MSG
    end
  end
end

describe Search::HyperEstraier, ".get_condition" do
  it "queryが設定されている場合 queryが設定されること" do
    cond = Search::HyperEstraier.get_condition("query")
    cond.phrase.should == "query"
  end
  it "optionsがSIMPLEに設定されていること" do
    cond = Search::HyperEstraier.get_condition("query")
    cond.options.should == Search::HyperEstraier::Condition::SIMPLE
  end
  describe "target_aidが設定されている場合" do
    before do
      INITIAL_SETTINGS['search_apps'] = { "app" => { "cache" => "http://cache:3000/cache" } }
    end
    it "正しいattrが設定されていること" do
      cond = Search::HyperEstraier.get_condition("query", "app")
      cond.attrs.should == ["@uri STRBW http://cache:3000/cache"]
    end
    describe "target_contentsが設定されている場合" do
      it "正しいattrが設定されていること" do
        cond = Search::HyperEstraier.get_condition("query", "app", "contents")
        cond.attrs.should == ["@uri STRBW http://cache:3000/cache/contents"]
      end
    end
  end
end

describe Search::HyperEstraier, ".get_node" do
  it "nodeを返すこと" do
    node = Search::HyperEstraier.get_node("node_url")
    node.should be_is_a(Search::HyperEstraier::Node)
  end
end
