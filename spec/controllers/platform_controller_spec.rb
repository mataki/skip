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

describe PlatformController, "パスワードでログインする場合" do
  before do
    @code = "111111"
    @password = "password"
    @user = mock_model(User, :code => @code)
  end
  describe "認証に成功する場合" do
    before do
      User.should_receive(:auth).with(@code, @password).and_return(@user)

      post :login, :login => { :key => @code, :password => @password }
    end
    it { response.should redirect_to(root_url) }
    it { session[:user_code].should == @code }
  end
  describe "認証に失敗した場合" do
    before do
      request.env['HTTP_REFERER'] = @back = "http://test.host/previous/page"
      User.should_receive(:auth).and_return(nil)

      post :login, :login => { :key => @code, :password => @password }
    end
    it { response.should redirect_to(:back) }
    it { flash[:auth_fail_message].should_not be_nil }
  end
end

describe PlatformController, "ログイン時にOpenIdのアカウントが渡された場合" do
  before do
    @registration = mock('registration')
    @registration_data = {'http://axschema.org/namePerson' => ['ほげ ふが'],
      'http://axschema.org/company/title' => ['経理'],
      'http://axschema.org/contact/email' => ['hoge@hoge.jp'],
      'http://axschema.org/namePerson/friendly' => ['opuser']
    }
    @registration.stub!(:data).and_return(@registration_data)
    @identity_url = 'http://op.example.com/hoge'
  end
  describe "正しく認証できた場合" do
    before do
      result = OpenIdAuthentication::Result[:successful]
      controller.should_receive(:authenticate_with_open_id).and_yield(result, @identity_url, @registration)
      @user = stub_model(User, :code => "hogehoge")
      @openid_identifier = stub_model(OpenidIdentifier, :url => @identity_url)
      @openid_identifier.stub!(:user_with_unused).and_return(@user)
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
          @return_to = 'http://www.openskip.org/return_to'
          session[:return_to] = @return_to
          post :login, :openid_url => @identity_url
        end

        it { response.should redirect_to(@return_to) }
      end
    end

    describe "Userが登録されていない場合" do
      before do
        OpenidIdentifier.should_receive(:find_by_url).and_return(nil)
      end
      it "create_user_fromが呼ばれること" do
        controller.should_receive(:create_user_from).with(@identity_url, @registration)

      post :login, :openid_url => @identity_url
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
  describe "通常のログアウト" do
    before do
      ENV['SKIPOP_URL'] = nil
      controller.should_receive(:reset_session)
      get :logout
    end
    it { response.should redirect_to(:controller => :platform, :action => :index) }
    it { flash[:notice].should_not be_nil }
  end
  describe "メッセージが設定されている場合" do
    before do
      ENV['SKIPOP_URL'] = nil
      controller.should_receive(:reset_session)
      @message = 'ほげほげ'

      get :logout, :message => @message
    end
    it { response.should redirect_to(:controller => :platform, :action => :index) }
    it { flash[:notice].should be_include('retired') }
  end
end

describe PlatformController, "#create_user_from" do
  before do
    @identity_url = "http://id.example.com/a_user/"
    @registration = mock('registration')
  end

  describe "専用OPモードの場合" do
    before do
      ENV['FREE_OP'] = nil
      ENV['SKIPOP_URL'] = 'http://skipop.url/'
    end
    describe "identity_urlが適切な場合" do
      before do
        @identity_url = 'http://skipop.url/user/a_user'

        @user = stub_model(User)
        User.should_receive(:create_with_identity_url).and_return(@user)
        controller.stub!(:create_user_params)
      end
      describe "ユーザの登録が成功した場合" do
        before do
          @code = 'openskip'
          @user.stub!(:code).and_return(@code)
          @user.should_receive(:valid?).and_return(true)
          controller.should_receive(:reset_session)

          @session = {}
          controller.stub!(:session).and_return(@session)

          controller.stub!(:redirect_to).with({ :controller => :portal })
        end
        it "登録画面へリダイレクトすること" do
          controller.should_receive(:redirect_to).with({ :controller => :portal })

          call_create_user_from
        end
        it "session[:user_code]にcodeが入っていること" do
          @session.should_receive(:[]=).with(:user_code, @code)

          call_create_user_from
        end
      end
      describe "ユーザの登録に失敗した場合" do
        before do
          @user.should_receive(:valid?).and_return(false)
        end
        it "ログイン前画面に遷移してエラー表示すること" do
          controller.should_receive(:set_error_message_from_user_and_redirect).with(@user)

          call_create_user_from
        end
      end
    end
  end
  describe "フリーOPモードの場合" do
    before do
      ENV['SKIPOP_URL'] = nil
      ENV['FREE_OP'] = 'ON'

      @session = {}
      @session.stub!(:[]=).with(:identity_url, @identity_url)
      controller.stub!(:session).and_return(@session)

      controller.stub!(:create_user_params)
      @user = stub_model(User)
      User.stub!(:new_with_identity_url).and_return(@user)

      controller.should_receive(:redirect_to).with(:controller => :portal, :action => :index)
    end
    it "session[:identity_url]にOPから取得したOpenID identifierを保存する" do
      @session.should_receive(:[]=).with(:identity_url, @identity_url)

      call_create_user_from
    end
  end
  describe "OP専用モードでない場合" do
    before do
      ENV['SKIPOP_URL'] = nil
      ENV['FREE_OP'] = nil
    end
    it "ログイン画面に遷移して、エラーメッセージを表示すること" do
      controller.should_receive(:set_error_message_not_create_new_user_and_redirect)

      call_create_user_from
    end
  end
  def call_create_user_from
    controller.send(:create_user_from, @identity_url, @registration)
  end
end

describe PlatformController, "#create_user_params" do
  before do
    @registration = mock('registration')
    @registration_data = {'http://axschema.org/namePerson' => ['ほげ ふが'],
      'http://axschema.org/contact/email' => ['hoge@hoge.jp'],
      'http://axschema.org/namePerson/friendly' => ['opuser']
    }
    @registration.stub!(:data).and_return(@registration_data)
    INITIAL_SETTINGS['ax_fetchrequest'] = [ ["http://axschema.org/namePerson", 'name'],
                                            ["http://axschema.org/contact/email", 'email'],
                                            ["http://axschema.org/namePerson/friendly", 'code']]
  end
  it "正しく整形されたもんが返却されること" do
    controller.send(:create_user_params, @registration).should == {:email=>"hoge@hoge.jp", :name=>"ほげ ふが", :code=>"opuser"}
  end
end

