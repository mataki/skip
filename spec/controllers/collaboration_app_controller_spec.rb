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

describe CollaborationAppController , 'GET /feed' do
  before do
    @current_user = user_login
  end
  it '設定されているパスに対してリソースの取得を試みること' do
    UserOauthAccess.should_receive(:resource).with('wiki', @current_user, 'path.rss').and_return('body')
    get :feed, :app_name => 'wiki', :path => 'path.rss', :gid => nil
  end
  it 'リクエストクエリにgidが含まれている場合はskip_gidパラメタ付きでリソースの取得を試みること' do
    UserOauthAccess.should_receive(:resource).with('wiki', @current_user, 'path.rss?skip_gid=gid').and_return('body')
    get :feed, :app_name => 'wiki', :path => 'path.rss', :gid => 'gid'
  end
  describe 'リソースの取得に成功する場合' do
    it 'feedが描画されること' do
      UserOauthAccess.stub!(:resource).and_yield(true, 'success_body')
      get :feed
      response.should render_template('feed')
    end
  end
  describe 'リソースの取得に失敗する場合' do
    it '「取得できませんでした。」と表示されること' do
      UserOauthAccess.stub!(:resource).and_yield(false, 'failuer_body')
      get :feed
      response.body.should == 'Retrieval failed.'
    end
  end
end
