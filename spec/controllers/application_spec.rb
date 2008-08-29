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
      User.should_receive(:find_by_uid).and_return(@user)
    end
    it { controller.current_user.should == @user }
  end
  describe 'session[:user_code]に一致するユーザが見つからない場合' do
    before do
      User.should_receive(:find_by_uid).and_return(nil)
    end
    it { controller.current_user.should == nil }
  end
end

describe ApplicationController, '#prepare_session' do
  before do
    controller.stub!(:controller_name).and_return('mypage')
    @session = {}
    @session.stub!('[]').with(:prepared).and_return(true)
    controller.stub!(:session).and_return(@session)
  end
  describe 'プロフィール情報が登録されていない場合' do
    before do
      controller.should_receive(:current_user).and_return(nil)
    end
    it 'platformにリダイレクトされること' do
      controller.should_receive(:redirect_to).with({:controller => '/platform', :error => 'no_profile'})
      controller.prepare_session
    end
  end
  describe 'プロフィール情報が登録されている場合' do
    before do
      @user = mock_model(User)
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
