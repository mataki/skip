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
  before do
    @registration = mock('registration')
    @registration_data = {'http://axschema.org/namePerson' => ['ほげ ふが'],
      'http://axschema.org/company/title' => ['経理'],
      'http://axschema.org/contact/email' => ['hoge@hoge.jp']}
    @registration.stub!(:data).and_return(@registration_data)
    @identity_url = 'http://op.example.com/opuser'
  end
  describe "正しく認証できた場合" do
    before do
      result = OpenIdAuthentication::Result[:successful]
      controller.should_receive(:authenticate_with_open_id).and_yield(result, @identity_url, @registration)
      @user = stub_model(User, :code => "hogehoge", :name => "hogehoge", :email => "hoge@hoge.jp", :section => "hoge" )
      @openid_identifier = stub_model(OpenidIdentifier, :url => @identity_url)
      @openid_identifier.stub!(:user).and_return(@user)
    end

    describe "ユーザが登録済みの場合" do
      before do
        OpenidIdentifier.should_receive(:find_by_url).and_return(@openid_identifier)
        controller.should_receive(:reset_session)
      end

      describe '直接アクセスした場合' do
        before do
          post :login, :openid_url => @identity_url
        end

        it "Sessionにユーザ情報が詰め込まれていること" do
          session[:user_code].should == @user.code
          session[:user_name].should == @user.name
          session[:user_email].should == @user.email
          session[:user_section].should == @user.section
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
          post :login, :openid_url => @identity_url, :return_to => 'http://example.com'
        end

        it { response.should redirect_to('http://example.com') }
      end
    end

    describe "Userが登録されていない場合" do
      before do
        OpenidIdentifier.should_receive(:find_by_url).and_return(nil)
      end
      describe "新規Userが作成可能な設定の場合" do
        before do
          ENV['SKIPOP_URL'] = 'http://op.example.com/'
          @user = stub_model(User)
        end
        describe "作成が成功する場合" do
          before do
            @user.should_receive(:valid?).and_return(true)
            User.should_receive(:create_with_identity_url).with(@identity_url, { :code => @identity_url.split("/").last, :name => 'ほげ ふが', :section => '経理', :email => 'hoge@hoge.jp' }).and_return(@user)
            post :login, :openid_url => @identity_url
          end
          it "Userを新規作成すること" do
          end
          it "Userにidentity_urlから抽出されたcodeが渡されること" do
          end
          it "ユーザ登録が面へ遷移すること" do
            response.should redirect_to(:controller => :portal)
          end
        end
        describe "作成が失敗する場合" do
          before do
            @user.should_receive(:valid?).and_return(false)
            User.should_receive(:create_with_identity_url).and_return(@user)
            post :login, :openid_url => @identity_url
          end
          it { response.should redirect_to(:controller => :platform, :action => :index) }
          it { flash[:auth_fail_message]["message"].should_not be_nil }
        end

      end
      describe "SKIPOP_URLが設定されていない場合設定の場合" do
        before do
          ENV['SKIPOP_URL'] = nil
          post :login, :openid_url => @identity_url
        end
        it { response.should be_redirect }
        it { response.should redirect_to(:controller => :platform, :action => :index) }
        it { flash[:auth_fail_message]["message"].should_not be_nil }
      end
      describe "identity_urlにSKIPOP_URLが含まれないない場合" do
        before do
          ENV['SKIPOP_URL'] = 'http://localhost:3000/'
          post :login, :openid_url => @identity_url
        end
        it { response.should be_redirect }
        it { response.should redirect_to(:controller => :platform, :action => :index) }
        it { flash[:auth_fail_message]["message"].should_not be_nil }
      end
    end
  end

  describe '認証に失敗した場合' do
    before do
      @result = OpenIdAuthentication::Result[:failed]
      controller.should_receive(:authenticate_with_open_id).and_yield(@result, @identity_url, @registration)
      post :login, :openid_url => @identity_url
    end

    it 'ログインページに遷移すること' do
      response.should redirect_to(:controller => :platform, :action => :login)
    end

    it 'flash が設定されていること' do
      flash[:auth_fail_message]["message"].should_not be_nil
    end
  end
end
