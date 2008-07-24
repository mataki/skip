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

describe PlatformController do
  before(:all) do
    Session.destroy_all
    @user_info = { "code" => "111111", "name" => SkipFaker.rand_char,
      "email" => SkipFaker.email, "section" => SkipFaker.rand_char }
    @referer = "http://localhost.jp/"
  end

  before(:each) do
    request.env["HTTP_REFERER"] = @referer
  end

  describe "初めてのログインの場合" do
    before(:each) do
      AccountAccess.should_receive(:auth).and_return(@user_info)
      @user = { :key => '111111', :password => 'passwd'}
      get :login, :login => @user
    end

    it "レスポンスがリダイレクトであること" do
      response.should be_redirect
    end

    it "Sessionテーブルにユーザのセッションが１列追加されていること" do
      Session.find_all_by_user_code(@user[:key]).size.should == 1
    end
  end

  describe "二度目のログインの場合" do
    before(:each) do
      AccountAccess.should_receive(:auth).twice.and_return(@user_info)
      @user = { :key => '111111', :password => 'passwd' }
      get :login, :login => @user, :login_save => true
      get :login, :login => @user, :login_save => true
    end

    it "レスポンスがリダイレクトであること" do
      response.should be_redirect
    end

    it "Sessionテーブルにユーザのセッションが２列追加されていること" do
      Session.find_all_by_user_code(@user[:key]).size.should == 2
    end

    it "失効期間が１ヶ月として設定されていること" do
      assert Session.find_all_by_user_code(@user[:key]).last.expire_date > Time.now + 1.month - 1.day
      assert Session.find_all_by_user_code(@user[:key]).last.expire_date < Time.now + 1.month + 1.day
    end
  end
end

describe PlatformController, "ログイン時にOpenIdのアカウントが渡された場合" do
  describe "正しく認証できた場合" do
    before do
      result = OpenIdAuthentication::Result[:successful]
      controller.should_receive(:authenticate_with_open_id).and_yield(result, 'http://hoge.example.com/')
      @account = stub_model(Account, :code => "hogehoge", :name => "hogehoge", :email => "hoge@hoge.jp", :section => "hoge" )
      @openid_identifier = stub_model(OpenidIdentifier, :url => 'http://hoge.example.com')
      @openid_identifier.stub!(:account).and_return(@account)
    end

    describe "ユーザが登録済みの場合" do
      before do
        OpenidIdentifier.should_receive(:find_by_url).and_return(@openid_identifier)
        controller.should_receive(:reset_session)
      end

      describe '直接アクセスした場合' do
        before do
          post :login, :openid_url => 'http://hoge.example.com/'
        end

        it "Sessionにユーザ情報が詰め込まれていること" do
          session[:user_code].should == @account.code
          session[:user_name].should == @account.name
          session[:user_email].should == @account.email
          session[:user_section].should == @account.section
        end

        it 'SSO の sid がクッキーに設定されていること' do
          cookies['_sso_sid'].should_not be_nil
        end

        it "root_urlに遷移すること" do
          response.should redirect_to(root_url)
        end
      end

      describe '戻り先が指定されている場合' do
        before do
          post :login, :openid_url => 'http://hoge.example.com/', :return_to => 'http://example.com'
        end

        it { response.should redirect_to('http://example.com') }
      end
    end

    describe "Accountが登録されていない場合" do
      before do
        OpenidIdentifier.should_receive(:find_by_url).and_return(nil)
        request.env['HTTP_REFERER'] = 'http://fuga.example.com/'
        post :login, :openid_url => "http://hoge.example.com"
      end

      it { response.should be_redirect }
      it { response.should redirect_to(:action => :index) }
      it { flash[:auth_fail_message]["message"].should_not be_nil }
    end
  end

  describe '認証に失敗した場合' do
    before do
      @result = OpenIdAuthentication::Result[:failed]
      controller.should_receive(:authenticate_with_open_id).and_yield(@result, 'http://hoge.example.com/')
      request.env['HTTP_REFERER'] = 'http://fuga.example.com/'
      post :login, :openid_url => 'http://hoge.example.com/'
    end

    it '前のページに遷移すること' do
      response.should redirect_to(:back)
    end

    it 'flash が設定されていること' do
      flash[:auth_fail_message]["message"].should_not be_nil
    end
  end
end
