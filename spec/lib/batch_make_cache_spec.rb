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
    SkipEmbedded::InitialSettings['protocol'] = 'http://'
    SkipEmbedded::InitialSettings['host_and_port'] = 'localhost:3000'
  end
  it "link_urlが正しく設定されること" do
    yaml = YAML.parse(@result)
    yaml[:link_url].value.should == "http://localhost:3000/user/hoge"
  end
end

describe BatchMakeCache, "#make_caches_bookmark" do
  before do
    @bmc = BatchMakeCache.new(1.hour)
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
      @bmc.make_caches_bookmark("bookmark", "cache/path")
    end
    it "コンテンツの内容に作者が存在していること" do
      @bmc.should_receive(:create_contents).with(:body_lines => ["title", "url", 10.minutes.ago.strftime("%Y年%m月%d日"), "creater", "tags,category", ""], :title => "title")
      @bmc.make_caches_bookmark("bookmark", "cache/path")
    end
    it "公開範囲が公開(sid:allusers)で設定されていること" do
      @bmc.should_receive(:create_meta).with(:contents_type => "bookmark", :publication_symbols => "sid:allusers,uid:creater", :link_url => "/bookmark/show/url", :icon_type => "tag_blue", :title => "title")
      @bmc.make_caches_bookmark("bookmark", "cache/path")
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
      @bmc.make_caches_bookmark("bookmark", "cache/path")
    end
    it "コンテンツの内容に公開している作者のみが存在していること" do
      @bmc.should_receive(:create_contents).with(:title => "title", :body_lines => ["title", "url", 10.minutes.ago.strftime("%Y年%m月%d日"), "creater1", "tags,category", ""])
      @bmc.make_caches_bookmark("bookmark", "cache/path")
    end
    it "公開範囲が公開(sid:allusers)で設定されていること" do
      @bmc.should_receive(:create_meta).with(:contents_type => "bookmark", :publication_symbols => "sid:allusers,uid:creater1,uid:creater2", :link_url => "/bookmark/show/url", :icon_type => "tag_blue", :title => "title")
      @bmc.make_caches_bookmark("bookmark", "cache/path")
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
      @bmc.make_caches_bookmark("bookmark", "cache/path")
    end
    it "コンテンツの内容にコメントの内容が設定されないこと" do
      @bmc.should_receive(:create_contents).with(:title => "title", :body_lines => ["title", "url"])
      @bmc.make_caches_bookmark("bookmark", "cache/path")
    end
    it "公開範囲が公開(sid:allusers)に設定されていないこと" do
      @bmc.should_receive(:create_meta).with(:contents_type => "bookmark", :publication_symbols => "uid:creater", :link_url => "/bookmark/show/url", :icon_type => "tag_blue", :title => "title")
      @bmc.make_caches_bookmark("bookmark", "cache/path")
    end
  end
end

describe BatchMakeCache, '#make_caches_user' do
  before do
    @bmc = BatchMakeCache.new
  end
  describe 'ユーザが見つかる場合' do
    before do
      @user = stub_model(User, :id => 'skip', :name => 'すきっぷ')
      User.should_receive(:find).and_return([@user])
    end
    it 'ファイルが出力されること' do
      body_lines = 'body_lines'
      @bmc.should_receive(:user_body_lines).with(@user).and_return(body_lines)
      contents = 'contents'
      @bmc.should_receive(:create_contents).with({:title => @user.name, :body_lines => body_lines}).and_return(contents)
      meta = 'meta'
      @bmc.should_receive(:create_meta).and_return(meta)
      contents_type = 'contents_type'
      cache_path = 'cache_path'
      @bmc.should_receive(:output_file).with(cache_path, contents_type, @user.id, contents, meta)
      @bmc.make_caches_user(contents_type, cache_path)
    end
  end
  describe 'ユーザが見つからない場合' do
    before do
      User.should_receive(:find).and_return([])
    end
    it 'ファイルが出力されないこと' do
      @bmc.should_not_receive(:output_file)
      @bmc.make_caches_user('contents_type', 'cache_path')
    end
  end
end

describe BatchMakeCache, '#user_body_lines' do
  before do
    @user = stub_model(User, :uid => 'uid', :name => 'name', :code => 'code', :email => 'email', :section => 'section')
    @user_profile_value = stub_model(UserProfileValue, :value => 'value')
    @user.stub!(:user_profile_values).and_return([@user_profile_value])
    @bmc = BatchMakeCache.new
  end
  describe 'メールアドレス公開設定の場合' do
    before do
      Admin::Setting.should_receive(:hide_email).and_return(false)
    end
    it 'メールアドレスが戻り値に含まれること' do
      @bmc.send(:user_body_lines, @user).should == ['uid', 'name', 'code', 'email', 'section', 'value']
    end
  end
  describe 'メールアドレス非公開設定の場合' do
    before do
      Admin::Setting.should_receive(:hide_email).and_return(true)
    end
    it 'メールアドレスが戻り値に含まれないこと' do
      @bmc.send(:user_body_lines, @user).should == ['uid', 'name', 'code', 'section', 'value']
    end
  end
end

describe BatchMakeCache, "#entry_body_lines" do
  before do
    @tb_entry_user = stub_model(User, :name => "trackback name")
    @tb_entry = stub_model(BoardEntry, :title => "trackback title", :user => @tb_entry_user)
    @trackback = stub_model(EntryTrackback, :tb_entry => @tb_entry)

    @comment_user = stub_model(User, :name => "comment name")
    @comment = stub_model(BoardEntryComment, :contents => "<<<\r\ncomment contents\r\n>>>", :user => @comment_user)

    @user = stub_model(User, :name => "user name")
    @entry = stub_model(BoardEntry, :title => "entry title", :category => "[cate][gory]", :contents => "entry contents",
                        :user => @user, :board_entry_comments => [@comment], :entry_trackbacks => [@trackback])
    @bmc = BatchMakeCache.new
  end
  it "配列に設定された値があること" do
    ["trackback name", "trackback title", "comment name", "<pre>\ncomment contents\n</pre>\n", "user name", "entry title", "[cate][gory]", "<p>entry contents</p>\n"].each do |s|
      @bmc.send(:entry_body_lines, @entry).should be_include(s)
    end
  end
  describe 'hikiの場合' do
    before do
      @entry.editor_mode = 'hiki'
    end
    describe '本文にhiki記法を含む場合' do
      before do
        @entry.contents = "<<<\r\nentry_contents\r\n>>>"
      end
      it 'html化されていること' do
        @bmc.send(:entry_body_lines, @entry).should be_include("<pre>\nentry_contents\n</pre>\n")
      end
    end
  end
  describe 'richの場合' do
    before do
      @entry.editor_mode = 'richtext'
    end
    describe '本文にhiki記法を含む場合' do
      before do
        @entry.contents = "<<<\r\nentry_contents\r\n>>>"
      end
      it 'html化されていないこと' do
        @bmc.send(:entry_body_lines, @entry).should be_include("<<<\r\nentry_contents\r\n>>>")
      end
    end
  end
end

