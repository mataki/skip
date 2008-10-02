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

describe ApplicationController, "#sso" do
  describe "固定OP利用設定の場合" do
    before do
      INITIAL_SETTINGS['login_mode'] = "rp"
      INITIAL_SETTINGS['fixed_op_url'] = 'http://localhost.com/'
      @return_to = 'http://www.openskip.org/return_to'
      controller.stub!(:request).and_return(mock('request', :url => @return_to))
    end
    describe "未ログイン時" do
      it "ログインへリダイレクトされる" do
        controller.stub!(:logged_in?).and_return(false)
        controller.should_receive(:redirect_to).with({:controller => '/platform', :action => :login, :openid_url => INITIAL_SETTINGS['fixed_op_url'], :return_to => @return_to})
        controller.send(:sso).should be_false
      end
    end

    describe "ログイン時" do
      it "trueを返す" do
        controller.stub!(:logged_in?).and_return(true)
        controller.send(:sso).should be_true
      end
    end
  end
end

describe ApplicationController, '#current_user' do
  before do
    @user = stub_model(User)
  end
  describe 'sessionからユーザを取得できる場合' do
    before do
      controller.should_receive(:login_from_session).and_return(@user)
    end
    it 'ユーザが返却されること' do
      controller.send(:current_user).should == @user
    end
  end
  describe 'sessionからユーザを取得できない場合' do
    before do
      controller.should_receive(:login_from_session).and_return(nil)
    end
    describe 'cookieからユーザを取得できる場合' do
      before do
        controller.should_receive(:login_from_cookie).and_return(@user)
      end
      it 'ユーザが返却されること' do
        controller.send(:current_user).should == @user
      end
    end
    describe 'cookieからユーザを取得できない場合' do
      before do
        controller.should_receive(:login_from_cookie).and_return(nil)
      end
      it 'ユーザが返却されないこと' do
        controller.send(:current_user).should be_nil
      end
    end
  end
end

describe ApplicationController, '#prepare_session' do
  before do
    controller.stub!(:controller_name).and_return('mypage')
    @session = mock('hash')
    @session.stub!('[]')
    @session.stub!('[]').with(:prepared).and_return(true)
    controller.stub!(:session).and_return(@session)
  end
  describe 'アクティブなユーザでない場合' do
    before do
      @user = mock_model(User)
      @user.stub!(:active?).and_return(false)
      controller.should_receive(:current_user).and_return(@user)
    end
    describe "退職済みユーザの場合" do
      before do
        @user.stub!(:retired?).and_return(true)
      end
      it "ログアウトにリダイレクトされること" do
        controller.should_receive(:redirect_to).with({ :controller => '/platform', :action => :logout, :message => 'retired' })
        controller.send(:prepare_session)
      end
    end
    describe "未登録ユーザの場合" do
      before do
        @user.stub!(:retired?).and_return(false)
      end
      it 'ユーザ登録画面にリダイレクトされること' do
        controller.should_receive(:redirect_to).with({ :controller => '/portal' })
        controller.send(:prepare_session)
      end
    end
  end
  describe 'アクティブなユーザの場合' do
    before do
      @user = mock_model(User)
      @user.stub!(:active?).and_return(true)
      controller.should_receive(:current_user).and_return(@user)
    end
    it { controller.send(:prepare_session).should be_true }
  end
end

describe ApplicationController, '#login_required' do
  describe 'ログイン中の場合' do
    before do
      @user = stub_model(User)
      controller.should_receive(:current_user).and_return(@user)
    end
    it { controller.send(:login_required).should be_true }
  end

  describe "ログインしていない場合" do
    before do
      controller.should_receive(:current_user).and_return(nil)

      @root_url = 'http://skip.openskip.org/'
      controller.should_receive(:root_url).and_return(@root_url)
    end
    after do
      controller.send(:login_required)
    end

    describe 'root_urlに遷移し来ていた場合' do
      before do
        controller.stub!(:request).and_return(mock('request', :url => @root_url))
      end
      it { controller.should_receive(:redirect_to).with(:controller => '/platform', :action => :index) }
    end
    describe 'その他のURLに遷移してきていた場合' do
      before do
        @other_url = 'http://skip.openskip.org/page/1234'
        controller.stub!(:request).and_return(mock('request', :url => @other_url))
      end
      it { controller.should_receive(:redirect_to).with(:controller => '/platform', :action => :require_login, :return_to => URI.encode(@other_url)) }
    end
  end
end

describe ApplicationController, '#login_from_session' do
  # TODO 後で書く
end

describe ApplicationController, '#login_from_cookie' do
  describe 'cookieにauth_tokenがある場合' do
    before do
      @cookies = {}
      @auth_token = 'auth_token'
      @cookies[:auth_token] = @auth_token
      controller.stub!(:cookies).and_return(@cookies)
    end
    describe 'usersテーブルにauth_tokenに一致する利用可能なレコードが存在する場合' do
      before do
        @user = stub_model(User)
        @user.stub!(:remember_token?).and_return(true)
        User.stub!(:find_by_remember_token).with(@auth_token).and_return(@user)
        controller.stub!(:handle_remember_cookie!)
      end
      it 'handle_remember_cookie!が呼ばれること' do
        controller.should_receive(:handle_remember_cookie!)
        controller.send(:login_from_cookie)
      end
      it 'そのuserを返すこと' do
        controller.send(:login_from_cookie).should == @user
      end
    end
    describe 'usersテーブルにauth_tokenに一致する利用可能なレコードが存在しない場合' do
      before do
        User.stub!(:find_by_remember_token).with(@auth_token).and_return(nil)
      end
      it 'nilを返すこと' do
        controller.send(:login_from_cookie).should be_nil
      end
    end
  end
  describe 'cookiesにauth_tokenがない場合' do
    before do
      @cookies = {}
      controller.stub!(:cookies).and_return(@cookies)
    end
    it 'nilを返すこと' do
      controller.send(:login_from_cookie).should be_nil
    end
  end
end
