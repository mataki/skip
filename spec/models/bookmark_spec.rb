# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008  TIS Inc.
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

describe Bookmark do
  describe ".get_title_from_url" do
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

  describe "#tags_as_string" do
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

end


# TODO: rake spec:rcov でエラーが発生する
# describe Bookmark do
#   describe ".get_query_param" do
#     describe "引数が user の場合" do
#       it { Bookmark.get_query_param("user").should == "/user/%" }
#     end
#     describe "引数がpageの場合" do
#       it { Bookmark.get_query_param("page").should == "/page/%" }
#     end
#     describe "引数がinternetの場合" do
#       it { Bookmark.get_query_param("internet").should == "http%" }
#     end
#   end

#   describe "ブックマークのタイプチェックメソッド" do
#     before do
#       @bookmark = Bookmark.new :url => "http://www.example.com/"
#     end

#     describe "#is_type_page?" do
#       describe "ページのブックマークの場合" do
#         before do
#           @bookmark.url = "/page/11"
#         end
#         it { @bookmark.should be_is_type_page }
#       end

#       describe "ページ以外のブックマークの場合" do
#         it { @bookmark.should_not be_is_type_page }
#       end
#     end

#     describe "is_type_user?" do
#       describe "ユーザのブックマークの場合" do
#         before do
#           @bookmark.url = "/user/hoge"
#         end
#         it { @bookmark.should be_is_type_user }
#       end

#       describe "ユーザ以外のブックマークの場合" do
#         it { @bookmark.should_not be_is_type_user }
#       end
#     end

#     describe "is_type_internet?" do
#       describe "インターネットのURLをブックマークしている場合" do
#         it { @bookmark.should be_is_type_internet }
#       end
#       describe "SKIP内のURLをブックマークしている場合" do
#         before do
#           @bookmark.url = "/page/1111"
#         end
#         it { @bookmark.should_not be_is_type_internet }
#       end
#     end
#   end

#   describe "#url_is_public?" do
#     before do
#       @bookmark = Bookmark.new :url => "/page/1111"
#     end
#     describe "ページのブックマークの場合" do
#       describe "ページが全公開の場合" do
#         before do
#           @entry = mock_model(BoardEntry)
#           @entry.should_receive(:public?).and_return(true)
#           BoardEntry.should_receive(:find_by_id).and_return(@entry)
#         end
#         it { @bookmark.should be_url_is_public }
#       end

#       describe "ページが全公開でない場合" do
#         before do
#           @entry = mock_model(BoardEntry)
#           @entry.should_receive(:public?).and_return(false)
#           BoardEntry.should_receive(:find_by_id).and_return(@entry)
#         end
#         it { @bookmark.should_not be_url_is_public }
#       end
#     end
#     describe "ページのブックマークでない場合" do
#       before do
#         @bookmark.url = "http://example.com/"
#       end
#       it { @bookmark.should be_url_is_public }
#     end
#   end

# end

describe Bookmark do
  fixtures :bookmarks, :bookmark_comments

  # 非公開コメントのみのブックマークは表示しない
  def test_find_visible
    bookmarks = Bookmark.find_visible(5)

    assert !( bookmarks.include? @a_private_bookmark )
    assert ( bookmarks.include? @a_public_bookmark )
    assert ( bookmarks.include? @a_mixed_bookmark )
  end

  # ブックマークされたURLが全公開可能か
  def test_url_is_public?
    # 全公開のエントリの場合 true
    assert @a_public_page_bookmark.url_is_public?
    # 全公開以外のエントリの場合 false
    assert !@a_private_page_bookmark.url_is_public?
    # 外部のURLの場合 true
    assert @a_bookmark.url_is_public?
  end
end
