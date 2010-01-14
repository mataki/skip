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

describe Bookmark, 'get_title_from_url' do
  describe "URLが正しく取得できた場合" do
    describe "TITLEが含まれている場合" do
      before do
        Bookmark.should_receive(:open).and_yield("hoge\n<TITLE>HOGE</TITLE>\nhoge")
      end
      it "タイトルを返す" do
        title = Bookmark.get_title_from_url "http://www.example.com/"
        title.should == "HOGE"
      end
    end

    describe "titleが含まれている場合" do
      before do
        Bookmark.should_receive(:open).and_yield("HOGE\n<title>hoge</title>\nHOGE")
      end
      it "タイトルを返す" do
        title = Bookmark.get_title_from_url "http://www.example.com/"
        title.should == "hoge"
      end
    end

    describe "titleが含まれていない場合" do
      before do
        Bookmark.should_receive(:open).and_yield("hoge\n<hoge>HOGE</hoge>\nhoge")
      end
      it "空文字列を返す" do
        title = Bookmark.get_title_from_url "http://www.example.com/"
        title.should == ""
      end

    end
  end

  describe "URLへ正しくアクセスできなかった場合" do
    before do
      Bookmark.should_receive(:open).and_raise(Exception)
      logger = mock("logger")
      logger.stub!(:error)
      Bookmark.should_receive(:logger).at_least(:once).and_return(logger)
      @title = Bookmark.get_title_from_url "http://www.example.com/"
    end

    it "ログへエラーメッセージを出力する" do
    end

    it "空文字列を返す" do
      @title.should == ""
    end
  end
end

describe Bookmark, "ブックマークのタイプチェックメソッド" do
  before do
    @bookmark = Bookmark.new :url => "http://www.example.com/"
  end

  describe "#is_type_page?" do
    describe "ページのブックマークの場合" do
      before do
        @bookmark.url = "/page/11"
      end
      it { @bookmark.should be_is_type_page }
    end

    describe "ページ以外のブックマークの場合" do
      it { @bookmark.should_not be_is_type_page }
    end
  end

  describe "is_type_internet?" do
    describe "インターネットのURLをブックマークしている場合" do
      it { @bookmark.should be_is_type_internet }
    end
    describe "SKIP内のURLをブックマークしている場合" do
      before do
        @bookmark.url = "/page/1111"
      end
      it { @bookmark.should_not be_is_type_internet }
    end
  end
end

describe Bookmark, '#escaped_url' do
  before do
    @bookmark = Bookmark.new
  end
  describe 'エスケープ済みのURLの場合' do
    before do
      @bookmark.url = 'http://ja.wikipedia.org/wiki/%E3%82%BD%E3%83%8B%E3%83%83%E3%82%AF'
    end
    it '正しくエスケープされること' do
      @bookmark.escaped_url.should == 'http://ja.wikipedia.org/wiki/%25E3%2582%25BD%25E3%2583%258B%25E3%2583%2583%25E3%2582%25AF'
    end
  end
  describe '未エスケープのURLの場合' do
    before do
      @bookmark.url = 'http://ja.wikipedia.org/wiki/ソニック'
    end
    it '正しくエスケープされること' do
      @bookmark.escaped_url.should == 'http://ja.wikipedia.org/wiki/%E3%82%BD%E3%83%8B%E3%83%83%E3%82%AF'
    end
  end
  describe 'エスケープ、未エスケープ混在のURLの場合' do
    before do
      @bookmark.url = 'http://ja.wikipedia.org/wiki/ソ%E3%83%8B%E3%83%83%E3%82%AF'
    end
    it '正しくエスケープされること' do
      @bookmark.escaped_url.should == 'http://ja.wikipedia.org/wiki/%E3%82%BD%25E3%2583%258B%25E3%2583%2583%25E3%2582%25AF'
    end
  end
  describe 'フラグメント付きのURLの場合' do
    before do
      @bookmark.url = 'http://ja.wikipedia.org/wiki/%E7%8C%AB#.E8.BA.AB.E4.BD.93.E7.9A.84.E7.89.B9.E5.BE.B4'
    end
    it '正しくエスケープされること' do
      @bookmark.escaped_url.should == 'http://ja.wikipedia.org/wiki/%25E7%258C%25AB%23.E8.BA.AB.E4.BD.93.E7.9A.84.E7.89.B9.E5.BE.B4'
    end
  end
  describe 'クエリ付きのURLの場合' do
    before do
      @bookmark.url = 'http://b.hatena.ne.jp/search?ie=utf8&q=vim+エディタ&x=0&y=0'
    end
    it '正しくエスケープされること' do
      @bookmark.escaped_url.should == 'http://b.hatena.ne.jp/search?ie=utf8&q=vim+%E3%82%A8%E3%83%87%E3%82%A3%E3%82%BF&x=0&y=0'
    end
  end
  describe 'シングルクォート付きのURLの場合' do
    before do
      @bookmark.url = "http://localhost?foo='bar'"
    end
    it 'シングルクォートがhtmlエスケープされること(&#39;に変換される)' do
      @bookmark.escaped_url.should == "http://localhost?foo=%27bar%27"
    end
  end
  # テストが通らない。なんらかの半端なバイト対策が必要。
  describe '半端なバイトになるエスケープシーケンス付きのURLの場合' do
    before do
      @bookmark.url = "http://localhost/%c0"
    end
    it 'invalid_urlが返ること' do
      @bookmark.escaped_url.should == 'invalid_url'
    end
  end
end

describe Bookmark, '.unescaped_url' do
  before do
    @url = "http://localhost?foo=%27bar%27"
  end
  it 'htmlエスケープされたシングルクォート付きのURLがアンエスケープされること' do
    Bookmark.unescaped_url(@url).should == "http://localhost?foo='bar'"
  end
  describe '半端なバイトになるエスケープシーケンス付きのURLの場合' do
    before do
      @url = "http://localhost/%c0"
    end
    it '半端なバイトエラー(InvalidMultiByteURIError)となること' do
      lambda do
        Bookmark.unescaped_url @url
      end.should raise_error(Bookmark::InvalidMultiByteURIError)
    end
  end
end

describe Bookmark, '#title' do
  before do
    @bookmark = Bookmark.new(:title => 'title')
  end
  describe '正常なURLの場合' do
    before do
      @bookmark.url = "http://localhost/"
    end
    it 'titleがモデルに登録されているものとなっていること' do
      @bookmark.title.should == 'title'
    end
  end
  describe '半端なバイトになるエスケープシーケンス付きのURLの場合' do
    before do
      @bookmark.url = "http://localhost/%c0"
    end
    it 'titleが[invalid url]となること' do
      @bookmark.title.should == 'invalid url'
    end
  end
end

describe Bookmark, "#url_is_public?" do
  before do
    @bookmark = Bookmark.new :url => "/page/1111"
  end
  describe "ページのブックマークの場合" do
    describe "ページが全公開の場合" do
      before do
        @entry = mock_model(BoardEntry)
        @entry.should_receive(:public?).and_return(true)
        BoardEntry.should_receive(:find_by_id).and_return(@entry)
      end
      it { @bookmark.should be_url_is_public }
    end

    describe "ページが全公開でない場合" do
      before do
        @entry = mock_model(BoardEntry)
        @entry.should_receive(:public?).and_return(false)
        BoardEntry.should_receive(:find_by_id).and_return(@entry)
      end
      it { @bookmark.should_not be_url_is_public }
    end
  end
  describe "ページのブックマークでない場合" do
    before do
      @bookmark.url = "http://example.com/"
    end
    it { @bookmark.should be_url_is_public }
  end
end

describe Bookmark, '.get_query_param' do
  describe "引数が user の場合" do
    it { Bookmark.get_query_param("user").should == "/user/%" }
  end
  describe "引数がpageの場合" do
    it { Bookmark.get_query_param("page").should == "/page/%" }
  end
  describe "引数がinternetの場合" do
    it { Bookmark.get_query_param("internet").should == "http%" }
  end
end

describe Bookmark, "#tags_as_string" do
  before do
    @comments = (1..2).map{|i| mock_model(BookmarkComment)}
  end
  describe "タグに複数コメントがついている場合" do
    before do
      @comments[0].should_receive(:tags).and_return("[hoge][fuga]")
      @comments[1].should_receive(:tags).and_return("[kuga][hoga]")
      @bookmark = Bookmark.new
      @bookmark.should_receive(:bookmark_comments).and_return(@comments)
    end
    it "コメントのタグがすべて連結されていること" do
      tags = @bookmark.tags_as_string
      tags.should == "[hoge][fuga][kuga][hoga]"
    end
  end
  describe "複数コメントに同じタグが含まれている場合" do
    before do
      @comments[0].should_receive(:tags).and_return("[hoge][fuga]")
      @comments[1].should_receive(:tags).and_return("[fuga][hoge]")
      @bookmark = Bookmark.new
      @bookmark.should_receive(:bookmark_comments).and_return(@comments)
    end
    it "ユニークになっていること" do
      tags = @bookmark.tags_as_string
      tags.should == "[hoge][fuga]"
    end
  end
end

