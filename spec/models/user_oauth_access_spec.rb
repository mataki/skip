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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UserOauthAccess, '.resource' do
  describe '不正なユーザが指定された場合' do
    describe 'Userクラスのインスタンスではない場合' do
      it '空文字が返ること' do
        UserOauthAccess.resource('wiki', mock('user'), 'path').should == ''
      end
    end
    describe 'idがnilまたは空の場合' do
      it '空文字が返ること' do
        UserOauthAccess.resource('wiki', stub(User, :id => nil), 'path').should == ''
      end
    end
  end
  describe '正しいユーザの場合' do
    before do
      @user = stub_model(User, :id => 99)
      @resource_body = 'resource_body'
      @user_oauth_access = stub_model(UserOauthAccess, :token => 'token', :secret => 'secret')
      @user_oauth_access.stub!(:resource).and_return(@resource_body)
    end
    describe '対象ユーザのOAuthアクセストークンが登録されていない場合' do
      before do
        UserOauthAccess.should_receive(:find_by_app_name_and_user_id).and_return(nil)
      end
      it '空文字が返ること' do
        UserOauthAccess.resource('wiki', @user, 'path').should == ''
      end
      it '対象ユーザのOAuthアクセストークンが登録されていない旨がロギングされること' do
        @user.should_receive(:to_s_log).with('[OAuth Token was not exist]')
        UserOauthAccess.resource('wiki', @user, 'path')
      end
      it 'ブロックを渡した場合は, 処理失敗となっていること' do
        UserOauthAccess.resource('wiki', @user, 'path') do |result, body|
          result.should be_false
        end
      end
    end
    describe '対象ユーザのOAuthアクセストークンが正しく登録されていない場合(NULLの場合)' do
      before do
        @user_oauth_access = stub_model(UserOauthAccess, :token => nil, :secret => nil)
        @user_oauth_access.should_not_receive(:resource)
        UserOauthAccess.should_receive(:find_by_app_name_and_user_id).and_return(@user_oauth_access)
      end
      it '空文字が返ること' do
        UserOauthAccess.resource('wiki', @user, 'path').should == ''
      end
      it 'ブロックを渡した場合は, 処理失敗となっていること' do
        UserOauthAccess.resource('wiki', @user, 'path') do |result, body|
          result.should be_false
        end
      end
    end
    describe '対象ユーザのOAuthアクセストークンが正しく登録されている場合' do
      before do
        @user_oauth_access.should_receive(:resource).and_return(@resource_body)
        UserOauthAccess.should_receive(:find_by_app_name_and_user_id).and_return(@user_oauth_access)
      end
      it 'リソースのBodyが取得できること' do
        UserOauthAccess.resource('wiki', @user, 'path').should == @resource_body
      end
      it 'ブロックを渡した場合は, 処理成功となっていること' do
        UserOauthAccess.resource('wiki', @user, 'path') do |result, body|
          result.should be_true
        end
      end
    end
    describe 'リソースの取得がタイムアウトする場合' do
      before do
        @user_oauth_access.should_receive(:resource).and_raise(TimeoutError.new('message'))
        UserOauthAccess.should_receive(:find_by_app_name_and_user_id).and_return(@user_oauth_access)
      end
      it '空文字が返ること' do
        UserOauthAccess.resource('wiki', @user, 'path').should == ''
      end
      it 'ブロックを渡した場合は, 処理失敗となっていること' do
        UserOauthAccess.resource('wiki', @user, 'path') do |result, body|
          result.should be_false
        end
      end
    end
  end
end

describe UserOauthAccess, '.sorted_feed_items' do
  describe 'feed_itemの取得件数が5件の場合' do
    before do
      UserOauthAccess.should_receive(:feed_items).and_return([
        stub_feed_item(Time.local(2009, 1, 3), '1/3wiki'),
        stub_feed_item(Time.local(2009, 1, 1), '1/1wiki'),
        stub_feed_item(Time.local(2009, 1, 5), '1/5wiki'),
        stub_feed_item(Time.local(2009, 1, 4), '1/4wiki'),
        stub_feed_item(Time.local(2009, 1, 2), '1/2wiki')
      ])
    end
    it 'feed_itemが5件取得されること' do
      UserOauthAccess.sorted_feed_items('rss_body').size.should == 5
    end
    it 'feed_itemが更新日の新しい順番に並んでいること' do
      UserOauthAccess.sorted_feed_items('rss_body').map do |item|
        item.title
      end.should == %w(1/5wiki 1/4wiki 1/3wiki 1/2wiki 1/1wiki)
    end
  end
  describe 'feed_itemの取得件数が21件の場合' do
    before do
      UserOauthAccess.should_receive(:feed_items).and_return(
        (0..20).map{|i| stub_feed_item(Time.local(2009, 1, i + 1), 'wiki')}
      )
    end
    it 'feed_itemが20件取得されること' do
      UserOauthAccess.sorted_feed_items('rss_body').size.should == 20
    end
  end
  def stub_feed_item date = Time.now, title = '', link = ''
    stub(Object, :date => date, :title => title, :link => link)
  end
end

describe UserOauthAccess, '.feed_items' do
  describe 'RSSとして妥当な文字列の場合' do
    before do
      @rss_body = <<-RUBY
<?xml version='1.0' encoding='utf-8' ?>
<rss version='2.0' xml:lang='ja' xmlns:content='http://purl.org/rss/1.0/modules/content/' xmlns:dc='http://purl.org/dc/elements/1.1/'>
  <channel>
    <title>あどみんのノート</title>
    <link>/notes</link>
    <description>aioue</description>
    <dc:creator>admin</dc:creator>
    <item>
      <title>[NEW]Vimのーと</title>
      <link>http://localhost:4000/notes/vimnote/pages/FrontPage</link>
      <dc:creator>vimnote</dc:creator>
      <pubDate>Mon, 25 May 2009 16:35:13 +0900</pubDate>
    </item>
  </channel>
</rss>
      RUBY
    end
    it 'サイズ1の配列が取得できること' do
      UserOauthAccess.feed_items(@rss_body).size.should == 1
    end
  end
  describe 'RSSとして不正な文字列の場合' do
    it 'サイズ0の配列が取得できること' do
      UserOauthAccess.feed_items('rss_body').should be_empty
    end
  end
end
