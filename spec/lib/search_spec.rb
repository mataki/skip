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

describe Search, "#initialize" do
  describe "検索クエリが入力されていない場合" do
    it "エラーが投げられること" do
      result = Search.new({ :query => "" } ,['sid:allusers'])
      result.error.should == Search::NO_QUERY_ERROR_MSG
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
      SkipEmbedded::InitialSettings["search_apps"] = {
        "SKIP" => { "meta" => "/hoge/fuga/meta", "cache" => "http://localhost:3000/app_cache" }
      }

      File.stub!(:file?).and_return(true)
      File.stub!(:open)
      YAML.stub!(:load).and_return({ "title" => "meta title", "publication_symbols" => "sid:allusers", "contents_type" => "meta", "link_url" => "http://localhost:3000/meta"})
    end
    it "メタ情報が返ってくること" do
      result = Search.get_metadata "contents", "http://localhost:3000/app_cache/hoge/fuga", "title"
      result.should == {:contents_type=>"meta", :publication_symbols=>"sid:allusers", :title=>"meta title", :contents=>"contents", :link_url=>"http://localhost:3000/meta"}
    end
  end
  describe "設定ファイルから取得される場合" do
    before do
      SkipEmbedded::InitialSettings["search_apps"] = {
        "SKIP" => { "cache" => "http://localhost:3000/app_cache" }
      }
    end
    it "icon_typeがある場合 設定ファイルから設定されること" do
      SkipEmbedded::InitialSettings["search_apps"] = {
        "SKIP" => { "cache" => "http://localhost:3000/app_cache", "icon_type" => "icon_a" }
      }
      result = Search.get_metadata "contents", "http://localhost:3000/app_cache/hoge/fuga", "title"
      result[:icon_type].should == "icon_a"
      result[:contents_type].should == "SKIP"
    end
    it "icon_typeがない場合 設定ファイルから設定されること" do
      result = Search.get_metadata "contents", "http://localhost:3000/app_cache/hoge/fuga", "title"
      result[:contents_type].should == "SKIP"
      result[:icon_type].should be_nil
    end
  end
  describe "cacheにヒットしない場合" do
    it "引数から設定されること" do
      SkipEmbedded::InitialSettings["search_apps"] = {}
      result = Search.get_metadata "contents", "http://localhost:3000/app_cache/hoge/fuga", "title"
      result[:title].should == "title"
      result[:publication_symbols].should == Symbol::SYSTEM_ALL_USER
      result[:link_url].should == "http://localhost:3000/app_cache/hoge/fuga"
    end
  end
end

describe Search, ".get_metadata_from_file" do
  before do
    @cache = "http://localhost:3000"
    @meta = "/path/to/meta"
    @uri_text = "http://localhost:3000/user/0000/1.html"
    @file_path = "/path/to/meta/user/0000/1.html"
    @yml = { :title => "ほげ ふが", :fuga => "1111" }
  end
  describe "ファイルが見付かる場合" do
    before do
      File.stub!(:file?).with(@file_path).and_return(true)
      File.stub!(:open).with(@file_path).and_return(@yml.to_yaml)
    end
    it "ファイルの内容が返ること" do
      result = Search.get_metadata_from_file(@uri_text, @cache, @meta)
      result.should == @yml
    end
  end
  describe "ファイルが見付からない場合" do
    before do
      File.stub!(:file?).with(@file_path).and_return(false)
    end
    it "ログを出力すること" do
      ActiveRecord::Base.should_receive(:logger).and_return(mock('logger', :error => "e"))
      Search.get_metadata_from_file(@uri_text, @cache, @meta)
    end
    it "publication_symbolsが sid:noneuser と登録されること" do
      result = Search.get_metadata_from_file(@uri_text, @cache, @meta)
      result[:publication_symbols].should == "sid:noneuser"
    end
  end
end
