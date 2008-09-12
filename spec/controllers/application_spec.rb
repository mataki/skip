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
  describe "SKIPOP設定の場合" do
    before do
      ENV['SKIPOP_URL'] = 'http://localhost.com/'
    end
    describe "未ログイン時" do
      it "ログインへリダイレクトされる" do
        controller.stub!(:logged_in?).and_return(false)
        controller.should_receive(:redirect_to).with({:controller => '/platform', :action => :login, :openid_url => ENV['SKIPOP_URL']})
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
  describe 'session[:user_code]に一致するユーザが見つかる場合' do
    before do
      @user = mock_model(User)
      User.should_receive(:find_by_code).and_return(@user)
    end
    it { controller.current_user.should == @user }
  end
  describe 'session[:user_code]に一致するユーザが見つからない場合' do
    before do
      User.should_receive(:find_by_code).and_return(nil)
    end
    it { controller.current_user.should == nil }
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
        controller.prepare_session
      end
    end
    describe "未登録ユーザの場合" do
      before do
        @user.stub!(:retired?).and_return(false)
      end
      it 'ユーザ登録画面にリダイレクトされること' do
        controller.should_receive(:redirect_to).with({ :controller => '/portal' })
        controller.prepare_session
      end
    end
  end
  describe 'アクティブなユーザの場合' do
    before do
      @user = mock_model(User)
      @user.stub!(:active?).and_return(true)
      controller.should_receive(:current_user).and_return(@user)
    end
    it { controller.prepare_session.should be_true }
  end
end

describe ApplicationController, '#require_admin' do
  describe '管理者じゃない場合' do
    before do
      @user = mock_model(User)
      @user.stub!(:admin).and_return(false)
      @user.stub!(:active?).and_return(true)
      controller.should_receive(:current_user).and_return(@user)
      @url = '/'
      controller.stub!(:root_url).and_return(@url)
      controller.stub!(:redirect_to).with(@url)
    end
    it 'mypageへのリダイレクト処理が呼ばれること' do
      controller.should_receive(:redirect_to).with(@url)
      controller.require_admin
    end
    it 'falseが返却されること' do
      controller.require_admin.should be_false
    end
  end
end

describe ApplicationController, '#login_required' do
  describe 'ログイン中の場合' do
    before do
      @user = stub_model(User)
      controller.should_receive(:current_user).and_return(@user)
    end
    it { controller.login_required.should be_true }
  end

  describe "ログインしていない場合" do
    before do
      controller.should_receive(:current_user).and_return(nil)

      @root_url = 'http://skip.openskip.org/'
      controller.should_receive(:root_url).and_return(@root_url)
    end
    after do
      controller.login_required
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
