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
      @user = stub_model(User, :code => "hogehoge", :name => "hogehoge")
      user_profile = stub_model(UserProfile, :email => 'hoge@hoge.jp', :section => '')
      @user.stub!(:user_profile).and_return(user_profile)
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

describe PlatformController, "#require_not_login" do
  describe "未ログイン状態のとき" do
    before do
      get :index
    end
    it { response.should be_success }
  end

  describe "ログイン中の時" do
    describe "params[:return_to]が設定されていない時" do
      before do
        user_login
        get :index
      end
      it { response.should redirect_to(root_url) }
    end
    describe "params[:return_to]が設定されている時" do
      before do
        user_login
        @return_to = 'http://test.com/'
        get :index, :return_to => @return_to
      end
      it { response.should redirect_to(@return_to) }
    end
  end

  describe "未登録ユーザでログインした時" do
    before do
      unused_user_login
      get :index
    end
    it { response.should redirect_to(:controller => :portal)}
  end
end

describe PlatformController, "#logout" do
  before do
    controller.should_receive(:reset_session)
    get :logout
  end
  it { response.should redirect_to(:controller => :platform, :action => :index) }
  it { flash[:notice].should_not be_nil }
end
