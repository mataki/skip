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

describe BatchMakeCache, "#create_meta" do
  before do
    bmc = BatchMakeCache.new
    params = { :title => "title",
      :contents_type => "page",
      :publication_symbols => "sid:allusers",
      :link_url => "/user/hoge",
      :icon_type => "icon"
    }
    @result = bmc.create_meta(params)
  end
  it "link_urlが正しく設定されること" do
    @result.should be_include("link_url: #{INITIAL_SETTINGS['protocol']}#{INITIAL_SETTINGS['host_and_port']}/user/hoge")
  end
end

describe BatchMakeCache, "#make_caches_bookmark" do
  before do
    @bmc = BatchMakeCache.new
    @bmc.stub!(:create_contents)
    @bmc.stub!(:create_meta)
    @bmc.stub!(:output_file)
  end
  describe "公開のブックマークコメントのみのブックマークの場合" do
    before do
      user = stub_model(User, :name => "creater", :uid => "creater")
      @bookmark = stub_model(Bookmark, :title => "title", :url => "url")
      @comment = stub_model(BookmarkComment, :bookmark_id => @bookmark.id, :user => user, :tags => "tags,category", :updated_on => 10.minutes.ago)
      @comment.stub!(:public).and_return(true)
      @bookmark.stub!(:bookmark_comments).and_return([@comment])

      BookmarkComment.should_receive(:find).and_return([@comment])
      Bookmark.should_receive(:find).and_return([@bookmark])
    end
    it "ファイルが出力されること" do
      @bmc.should_receive(:output_file)
      @bmc.make_caches_bookmark("bookmark", "cache/path", 1.hour.ago)
    end
    it "コンテンツの内容に作者が存在していること" do
      @bmc.should_receive(:create_contents).with(:title => "title", :body_lines => ["title", "url", "2008年10月28日", "creater", "tags,category", ""])
      @bmc.make_caches_bookmark("bookmark", "cache/path", 1.hour.ago)
    end
    it "公開範囲が公開(sid:allusers)で設定されていること" do
      @bmc.should_receive(:create_meta).with(:contents_type => "bookmark", :publication_symbols => "sid:allusers,uid:creater", :link_url => "/bookmark/show/url", :icon_type => "book", :title => "title")
      @bmc.make_caches_bookmark("bookmark", "cache/path", 1.hour.ago)
    end
  end

  describe "ブックマークコメントが公開と非公開ともにあった場合ブックマークの場合" do
    before do
      users = (1..2).map{|i| stub_model(User, :name => "creater#{i}", :uid => "creater#{i}")}
      @bookmark = stub_model(Bookmark, :title => "title", :url => "url")
      @comments = (0..1).map{|i| stub_model(BookmarkComment, :bookmark_id => @bookmark.id, :user => users[i], :tags => "tags,category", :updated_on => 10.minutes.ago)}
      @comments.first.stub!(:public).and_return(true)
      @comments.last.stub!(:public).and_return(false)
      @bookmark.stub!(:bookmark_comments).and_return(@comments)

      BookmarkComment.should_receive(:find).and_return(@comments)
      Bookmark.should_receive(:find).and_return([@bookmark])
    end
    it "ファイルが出力されること" do
      @bmc.should_receive(:output_file)
      @bmc.make_caches_bookmark("bookmark", "cache/path", 1.hour.ago)
    end
    it "コンテンツの内容に公開している作者のみが存在していること" do
      @bmc.should_receive(:create_contents).with(:title => "title", :body_lines => ["title", "url", "2008年10月28日", "creater1", "tags,category", ""])
      @bmc.make_caches_bookmark("bookmark", "cache/path", 1.hour.ago)
    end
    it "公開範囲が公開(sid:allusers)で設定されていること" do
      @bmc.should_receive(:create_meta).with(:contents_type => "bookmark", :publication_symbols => "sid:allusers,uid:creater1,uid:creater2", :link_url => "/bookmark/show/url", :icon_type => "book", :title => "title")
      @bmc.make_caches_bookmark("bookmark", "cache/path", 1.hour.ago)
    end
  end

  describe "非公開のブックマークコメントのみのブックマークの場合" do
    before do
      user = stub_model(User, :name => "creater", :uid => "creater")
      @bookmark = stub_model(Bookmark, :title => "title", :url => "url")
      @comment = stub_model(BookmarkComment, :bookmark_id => @bookmark.id, :user => user, :tags => "tags,category", :updated_on => 10.minutes.ago)
      @comment.stub!(:public).and_return(false)
      @bookmark.stub!(:bookmark_comments).and_return([@comment])

      BookmarkComment.should_receive(:find).and_return([@comment])
      Bookmark.should_receive(:find).and_return([@bookmark])
    end
    it "ファイルが出力されること" do
      @bmc.should_receive(:output_file)
      @bmc.make_caches_bookmark("bookmark", "cache/path", 1.hour.ago)
    end
    it "コンテンツの内容にコメントの内容が設定されないこと" do
      @bmc.should_receive(:create_contents).with(:title => "title", :body_lines => ["title", "url"])
      @bmc.make_caches_bookmark("bookmark", "cache/path", 1.hour.ago)
    end
    it "公開範囲が公開(sid:allusers)に設定されていないこと" do
      @bmc.should_receive(:create_meta).with(:contents_type => "bookmark", :publication_symbols => "uid:creater", :link_url => "/bookmark/show/url", :icon_type => "book", :title => "title")
      @bmc.make_caches_bookmark("bookmark", "cache/path", 1.hour.ago)
    end
  end
end
