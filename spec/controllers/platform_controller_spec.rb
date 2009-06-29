# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
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

describe PlatformController, "#login(パスワードでのログイン)" do
  before do
    @code = "111111"
    @password = "password"
    @user = User.new
    @user.stub!(:code).and_return(@code)
    User.stub!(:auth)
    session[:request_token] = 'request_token'
  end
  it 'セッションとクッキーがクリアされること' do
    controller.should_receive(:logout_killing_session!)
    login
  end
  describe "認証に成功する場合" do
    before do
      request.env['HTTP_REFERER'] = @back = "http://test.host/previous/page"
      User.should_receive(:auth).with(@code, @password, anything()).and_return(@user)
      controller.stub!(:handle_remember_cookie!)
    end
    describe 'ロックされている場合' do
      before do
        @user.should_receive(:locked?).and_return(true)
      end
      it '前のページにリダイレクトされること' do
        login
        response.should redirect_to(:back)
      end
      it 'エラーメッセージが設定されること' do
        login
        flash[:error].should_not be_nil
      end
      it 'ログインに失敗した旨のログ出力が行われること' do
        @user.should_receive(:to_s_log).with('[Login failed with password]')
        login
      end
    end
    describe 'ロックされていない場合' do
      before do
        @user.should_receive(:locked?).and_return(false)
      end
      describe 'パスワードの有効期限切れの場合' do
        before do
          @user.should_receive(:within_time_limit_of_password?).and_return(false)
        end
        it '前のページにリダイレクトされること' do
          login
          response.should redirect_to(:back)
        end
        it 'エラーメッセージが設定されること' do
          login
          flash[:error].should_not be_nil
        end
        it 'ログインに失敗した旨のログ出力が行われること' do
          @user.should_receive(:to_s_log).with('[Login failed with password]')
          login
        end
      end
      describe 'パスワードが有効期限内の場合' do
        before do
          @user.should_receive(:within_time_limit_of_password?).and_return(true)
        end
        it 'root_urlにリダイレクトされること' do
          login
          response.should redirect_to(root_url)
        end
        it 'current_userが設定されること' do
          login
          controller.send!(:current_user).should == @user
        end
        it "session[:request_token]の値が保持されていること" do
          login
          session[:request_token].should == "request_token"
        end
        it 'ログインに成功した旨のログ出力が行われること' do
          @user.should_receive(:to_s_log).with('[Login successful with password]')
          login
        end
        describe '「次回から自動的にログイン」にチェックがついている場合' do
          it 'handle_remember_cookie!(true)が呼ばれること' do
            controller.should_receive(:handle_remember_cookie!).with(true)
            login(true)
          end
        end
        describe '「次回から自動的にログイン」にチェックがついていない場合' do
          it 'handle_remember_cookie!(false)が呼ばれること' do
            controller.should_receive(:handle_remember_cookie!).with(false)
            login
          end
        end
      end
    end
  end
  describe "認証に失敗した場合" do
    before do
      request.env['HTTP_REFERER'] = @back = "http://test.host/previous/page"
      User.should_receive(:auth).and_return(nil)
    end
    it '前のページにリダイレクトされること' do
      login
      response.should redirect_to(:back)
    end
    it 'エラーメッセージが設定されること' do
      login
      flash[:error].should_not be_nil
    end
    it 'ログインに失敗した旨のログ出力が行われること' do
      User.should_receive(:to_s_log).with('[Login failed with password]', @code)
      login
    end
  end
  def login login_save = false
    if login_save
      post :login, :login => { :key => @code, :password => @password }, :login_save => 'true'
    else
      post :login, :login => { :key => @code, :password => @password }
    end
  end
end

describe PlatformController, "#login(OpenIDでのログイン)" do
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
      @auth_token = 'auth_token'
      @openid_identifier = stub_model(OpenidIdentifier, :url => @identity_url)
      @openid_identifier.stub!(:user_with_unused).and_return(@user)
    end

    describe "ユーザが登録済みの場合" do
      before do
        OpenidIdentifier.should_receive(:find_by_url).and_return(@openid_identifier)
        controller.should_receive(:reset_session)
        controller.should_receive(:current_user=).with(@user)
      end

      describe '直接アクセスした場合' do
        it "root_urlに遷移すること" do
          post :login, :openid_url => @identity_url
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
      response.should redirect_to(:action => :index)
    end

    it 'flash が設定されていること' do
      flash[:error].should_not be_nil
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
    user_login
  end
  describe "固定OP利用RPモードの場合" do
    before do
      SkipEmbedded::InitialSettings.stub!("[]").with('login_mode').and_return("rp")
      SkipEmbedded::InitialSettings.stub!("[]").with('fixed_op_url').and_return('http://skipop.url/')
    end
    it 'セッションとクッキーがクリアされること' do
      controller.should_receive(:logout_killing_session!)
      get :logout
    end
    it "OPのログアウトにリダイレクトすること" do
      get :logout
      response.should redirect_to("#{SkipEmbedded::InitialSettings['fixed_op_url']}logout")
    end
  end
  describe "その他のモードの場合" do
    before do
      SkipEmbedded::InitialSettings.stub!("[]").with('login_mode').and_return('password')
    end
    describe "通常のログアウト" do
      before do
        controller.should_receive(:reset_session)
        get :logout
      end
      it { response.should redirect_to(:controller => :platform, :action => :index) }
      it { flash[:notice].should_not be_nil }
    end
    describe "メッセージが設定されている場合" do
      before do
        controller.should_receive(:reset_session)
        @message = 'ほげほげ'

        get :logout, :message => @message
      end
      it { response.should redirect_to(:controller => :platform, :action => :index) }
      it { flash[:notice].should be_include('retired') }
    end
  end
end

describe PlatformController, 'GET /forgot_password' do
  describe 'パスワード再設定機能が有効な場合' do
    before do
      controller.stub!(:enable_forgot_password?).and_return(true)
    end
    it 'パスワード再設定画面に遷移すること' do
      get :forgot_password
      response.should be_success
    end
  end
  describe 'パスワード再設定機能が無効な場合' do
    before do
      controller.stub!(:enable_forgot_password?).and_return(false)
    end
    it '404エラーになること' do
      get :forgot_password
      response.code.should == '404'
    end
  end
end

describe PlatformController, 'POST /forgot_password' do
  describe 'パスワード再設定機能が有効な場合' do
    before do
      User.stub!(:find_by_email)
      controller.stub!(:enable_forgot_password?).and_return(true)
    end
    describe 'メールアドレスの入力がない場合' do
      it 'メールアドレスの入力は必須である旨のメッセージを表示する' do
        post :forgot_password, :email => ''
        flash[:error].should == 'Email is mandatory.'
        response.should be_success
      end
    end
    describe '登録済みのメールアドレスが送信された場合' do
      before do
        @email = 'exist@example.com'
        @user = stub_model(User, :email => @email, :active? => true)
        User.should_receive(:find_by_email).and_return(@user)
      end
      describe '利用開始済みのユーザの場合' do
        before do
          @password_reset_url = 'password_reset_url'
          controller.stub!(:reset_password_url).and_return(@password_reset_url)
          @user.stub!(:reset_auth_token).and_return(@reset_auth_token)
          @user.stub!(:issue_reset_auth_token)
          @user.stub!(:save_without_validation!)
          UserMailer.stub!(:deliver_sent_forgot_password)
        end
        it 'パスワードリセットURLを記載したメールの送信処理が呼ばれること' do
          UserMailer.should_receive(:deliver_sent_forgot_password).with(@email, @password_reset_url)
          post :forgot_password, :email => @email
        end
        it 'パスワードリセットコード発行処理が行われること' do
          @user.should_receive(:issue_reset_auth_token)
          @user.should_receive(:save_without_validation!)
          post :forgot_password, :email => @email
        end
        it 'メール送信した旨のメッセージが設定されてリダイレクトされること' do
          post :forgot_password, :email => @email
          flash[:notice].should_not be_nil
          response.should be_redirect
        end
      end
      describe '未使用ユーザの場合' do
        before do
          @user.stub!(:active?).and_return(false)
        end
        it "未登録ユーザのメールアドレスである旨のメッセージが設定されること" do
          post :forgot_password, :email => @email
          flash[:error].should == "User has entered email address #{@email} is not in use. Please start with the site."
          response.should render_template('forgot_password')
        end
      end
    end
    describe '未登録のメールアドレスが送信された場合' do
      before do
        User.should_receive(:find_by_email).and_return(nil)
      end
      it 'メールアドレスが未登録である旨のメッセージが設定されること' do
        post :forgot_password, :email => 'forgot_password@example.com'
        flash[:error].should_not be_nil
        response.should be_success
      end
    end
  end
  describe 'パスワード再設定機能が無効な場合' do
    before do
      controller.stub!(:enable_forgot_password?).and_return(false)
    end
    it '404エラーになること' do
      post :forgot_password
      response.code.should == '404'
    end
  end
end

describe PlatformController, 'GET /reset_password' do
  before do
    @expires_at = Time.local(2008, 11, 1)
    @user = stub_model(User, :reset_auth_token_expires_at => @expires_at)
  end
  describe 'パスワードリセットコードに一致するユーザが存在する場合' do
    before do
      User.should_receive(:find_by_reset_auth_token).and_return(@user)
    end
    describe 'パスワードリセットコードが作成されてから24時間以内の場合' do
      it '24時間未満の場合はパスワードリセット画面に遷移すること' do
        Time.stub!(:now).and_return(@expires_at.ago(1.second))
        get :reset_password, :code => '991ea5ca6502e3ded9e494c9c5ae50ad356e4f4a'
        response.should be_success
      end
      it 'ちょうど24時間の場合はパスワードリセット画面に遷移すること' do
        Time.stub!(:now).and_return(@expires_at)
        get :reset_password, :code => '991ea5ca6502e3ded9e494c9c5ae50ad356e4f4a'
        response.should be_success
      end
    end
    describe 'パスワードリセットコードが作成されてから24時間を越えている場合' do
      before do
        Time.stub!(:now).and_return(@expires_at.since(1.second))
        get :reset_password, :code => '991ea5ca6502e3ded9e494c9c5ae50ad356e4f4a'
      end
      it { flash[:error].should_not be_nil }
      it { response.should be_redirect }
    end
  end
  describe 'パスワードリセットコードに一致するユーザが存在しない場合' do
    before do
      User.should_receive(:find_by_reset_auth_token).and_return(nil)
    end
    it 'ログイン画面にリダイレクトされること' do
      get :reset_password, :code => '991ea5ca6502e3ded9e494c9c5ae50ad356e4f4a'
      response.should be_redirect
    end
  end
end

describe PlatformController, 'POST /reset_password' do
  before do
    @password = 'password'
    @password_confirmation = 'password'
    @expires_at = Time.local(2008, 11, 1)
  end
  def post_reset_password
    post :reset_password, :user => {:password => @password, :password_confirmation => @password_confirmation}, :code => '991e5ca6502e3ded9e494c9c5ae50ad356e4f4a'
  end
  describe 'パスワードリセットコードに一致するユーザが存在する場合' do
    before do
      @user = stub_model(User, :reset_auth_token_expires_at => @expires_at)
      User.stub!(:find_by_reset_auth_token).and_return(@user)
    end
    describe 'パスワードリセットコードが作成されてから24時間以内の場合' do
      before do
        Time.stub!(:now).and_return(@expires_at)
        @user.should_receive(:password=).with(@password)
        @user.should_receive(:password_confirmation=).with(@password_confirmation)
      end
      describe 'パスワードリセットに成功する場合' do
        before do
          @user.should_receive(:save).and_return(true)
          User.should_receive(:find_by_reset_auth_token).and_return(@user)
          post_reset_password
        end
        it { flash[:notice].should_not be_nil }
        it { response.should be_redirect }
      end
      describe 'パスワードリセットに失敗する場合' do
        before do
          @user.should_receive(:save).and_return(false)
          User.should_receive(:find_by_reset_auth_token).and_return(@user)
          post_reset_password
        end
        it { flash[:error].should_not be_nil }
        it { response.should be_success }
      end
    end
    describe 'パスワードリセットコードが作成されてから24時間を越えている場合' do
      before do
        Time.stub!(:now).and_return(@expires_at.since(1.second))
        post_reset_password
      end
      it { flash[:error].should_not be_nil }
      it { response.should be_redirect }
    end
  end
  describe 'パスワードリセットコードに一致するユーザが存在しない場合' do
    before do
      User.should_receive(:find_by_reset_auth_token).and_return(nil)
    end
    it 'ログイン画面にリダイレクトされること' do
      post_reset_password
      response.should be_redirect
    end
  end
end

describe PlatformController, 'GET /activate' do
  before do
    controller.stub!(:enable_activate?).and_return(true)
  end
  it 'サインアップ画面に遷移すること' do
    get :activate
    response.should be_success
  end
end

describe PlatformController, 'POST /activate' do
  before do
    User.stub!(:find_by_email)
    controller.stub!(:enable_activate?).and_return(true)
  end
  describe 'メールアドレスの入力がない場合' do
    it 'メールアドレスの入力は必須である旨のメッセージを表示する' do
      post :activate, :email => ''
      flash[:error].should == 'メールアドレスは必須です。'
      response.should be_success
    end
  end
  describe '登録済みのメールアドレスが送信された場合' do
    before do
      @email = 'exist@example.com'
      @user = stub_model(User, :email => @email, :activation_token => @activation_token)
      @signup_url = 'signup_url'
      controller.stub!(:signup_url).and_return(@signup_url)
      @user.stub!(:issue_activation_code)
      @user.stub!(:save_without_validation!)
      UserMailer.stub!(:deliver_sent_activate)
      User.should_receive(:find_by_email).and_return(@user)
    end
    describe '未使用ユーザが見つかる場合' do
      before do
        @user.should_receive(:unused?).and_return(true)
      end
      it 'アクティベーションURLを記載したメールの送信処理が呼ばれること' do
        UserMailer.should_receive(:deliver_sent_activate).with(@email, @signup_url)
        post :activate, :email => @email
      end
      it 'アクティベーションコード発行処理が行われること' do
        @user.should_receive(:issue_activation_code)
        @user.should_receive(:save_without_validation!)
        post :activate, :email => @email
      end
      it 'メール送信した旨のメッセージが設定されてリダイレクトされること' do
        post :activate, :email => @email
        flash[:notice].should_not be_nil
        response.should be_redirect
      end
    end
    describe '未使用ユーザが見つからない場合' do
      before do
        @user.should_receive(:unused?).and_return(false)
      end
      it '既に利用開始済みである旨のメッセージが設定されること' do
        post :activate, :email => @email
        flash[:error].should_not be_nil
        response.should be_success
      end
    end
  end
  describe '未登録のメールアドレスが送信された場合' do
    before do
      User.should_receive(:find_by_email).and_return(nil)
    end
    it 'メールアドレスが未登録である旨のメッセージが設定されること' do
      post :activate, :email => 'activate@example.com'
      flash[:error].should_not be_nil
      response.should be_success
    end
  end
end

describe PlatformController, 'GET /signup' do
  before do
    @expires_at = Time.local(2008, 11, 1)
    @user = stub_model(User, :activation_token_expires_at => @expires_at)
    @user.stub!(:within_time_limit_of_activation_token?).and_return(true)
    controller.stub!(:enable_signup?).and_return(true)
  end
  describe 'アクティベーションコードに一致するユーザが存在する場合' do
    before do
      User.should_receive(:find_by_activation_token).and_return(@user)
    end
    describe '有効期限内のアクティベーションコードの場合' do
      before do
        @user.should_receive(:within_time_limit_of_activation_token?).and_return(true)
        controller.should_receive(:current_user=).with(@user)
      end
      it 'アクティベート画面に遷移すること' do
        get :signup, :code => '991ea5ca6502e3ded9e494c9c5ae50ad356e4f4a'
        response.should be_redirect
      end
    end
    describe '有効期限外のアクティベーションコードの場合' do
      before do
        @user.should_receive(:within_time_limit_of_activation_token?).and_return(false)
        get :signup, :code => '991ea5ca6502e3ded9e494c9c5ae50ad356e4f4a'
      end
      it { flash[:error].should_not be_nil }
      it { response.should be_redirect }
    end
  end
  describe 'アクティベーションコードに一致するユーザが存在しない場合' do
    before do
      User.should_receive(:find_by_activation_token).and_return(nil)
    end
    it 'ログイン画面にリダイレクトされること' do
      get :signup, :code => '991ea5ca6502e3ded9e494c9c5ae50ad356e4f4a'
      response.should be_redirect
    end
  end
end

describe PlatformController, "#create_user_from" do
  before do
    @identity_url = "http://id.example.com/a_user/"
    @registration = mock('registration')
  end

  describe "専用OPモードの場合" do
    before do
      SkipEmbedded::InitialSettings.stub!("[]").with('login_mode').and_return('rp')
      SkipEmbedded::InitialSettings.stub!("[]").with('fixed_op_url').and_return('http://skipop.url/')
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
          controller.should_receive(:current_user=).with(@user)

          controller.stub!(:redirect_to).with({ :controller => :portal })
        end
        it "登録画面へリダイレクトすること" do
          controller.should_receive(:redirect_to).with({ :controller => :portal })

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
      SkipEmbedded::InitialSettings.stub!("[]").with('login_mode').and_return('rp')
      SkipEmbedded::InitialSettings.stub!("[]").with('fixed_op_url').and_return(nil)

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
      SkipEmbedded::InitialSettings.stub!("[]").with('login_mode').and_return('password')
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
    @registration = {
      "http://axschema.org/namePerson/friendly" => ["opuser"],
      "http://axschema.org/namePerson" => ["ほげ ふが"],
      "http://axschema.org/contact/email" => ["hoge@hoge.host"]
    }
    SkipEmbedded::InitialSettings.stub!("[]").with('ax_fetchrequest').and_return({
      :name => "http://axschema.org/namePerson",
      :email => "http://axschema.org/contact/email",
      :code => "http://axschema.org/namePerson/friendly"
    })
  end
  it "正しく整形されたもんが返却されること" do
    controller.send(:create_user_params, @registration).should == {:email=>"hoge@hoge.host", :name=>"ほげ ふが", :code=>"opuser"}
  end
end

describe PlatformController, "GET /forgot_openid" do
  describe 'OpenID忘れ機能が有効な場合' do
    before do
      controller.should_receive(:enable_forgot_openid?).and_return(true)
    end
    it "OpenID再設定画面が表示されること" do
      get :forgot_openid
      response.should render_template("forgot_openid")
    end
  end
  describe 'OpenID忘れ機能が無効な場合' do
    before do
      controller.should_receive(:enable_forgot_openid?).and_return(false)
    end
    it '404エラーになること' do
      get :forgot_openid
      response.code.should == '404'
    end
  end
end

describe PlatformController, "POST /forgot_openid" do
  describe 'OpenID忘れ機能が有効な場合' do
    before do
      User.delete_all
      controller.should_receive(:enable_forgot_openid?).and_return(true)
      @params_email = "a_user@example.com"
      @reset_url = "reset_url"
      controller.stub!(:reset_openid_url).and_return(@reset_url)
    end
    describe "登録されているemailが送信された場合" do
      before do
        @user = mock_model(User, :reset_auth_token => "reset_token", :issue_reset_auth_token => nil, :save_without_validation! => nil)
        User.should_receive(:find_by_email).with(@params_email).and_return(@user)
      end
      describe "emailに該当するユーザが利用中の場合" do
        before do
          @user.stub!(:active?).and_return(true)
        end
        it "ログイン画面にリダイレクトされること" do
          post_forgot_openid
          response.should redirect_to(:action => :index)
        end
        it "メールが送信されること" do
          UserMailer.should_receive(:deliver_sent_forgot_openid).with(@params_email, @reset_url)
          post_forgot_openid
        end
        it "該当するユーザのissue_reset_auth_tokenが呼ばれて、saveされること" do
          @user.should_receive(:issue_reset_auth_token)
          @user.should_receive(:save_without_validation!)
          post_forgot_openid
        end
      end
      describe "emailに該当するユーザが利用中でない場合" do
        before do
          @user.stub!(:active?).and_return(false)
        end
        it "入力画面がレンダリングされること" do
          post_forgot_openid
          response.should render_template('forgot_openid')
        end
        it "flashメッセージが登録されていること" do
          post_forgot_openid
          flash[:error].should == "入力された#{@params_email}のユーザは、利用開始されていません。利用開始してください。"
        end
      end
    end
    describe "登録されていないemailが送信された場合" do
      it "入力画面がレンダリングされること" do
        post_forgot_openid
        response.should render_template('forgot_openid')
      end
      it "flashメッセージが登録されていること" do
        post_forgot_openid
        flash[:error].should == "入力された#{@params_email}というメールアドレスは登録されていません。"
      end
    end
    def post_forgot_openid
      post :forgot_openid, :email => @params_email
    end
  end
  describe 'OpenID忘れ機能が無効な場合' do
    before do
      controller.should_receive(:enable_forgot_openid?).and_return(false)
    end
    it '404エラーになること' do
      post :forgot_openid
      response.code.should == '404'
    end
  end
end

describe PlatformController, "GET /reset_openid" do
  before do
    @reset_token = "reset_token"
    @identity_url = "http://openid.example.com/user/a_user"
  end
  describe "トークンが見つかる場合" do
    before do
      @identifier = mock_model(OpenidIdentifier)
      @user = mock_model(User, :openid_identifiers => [@identifier])
      User.stub!(:find_by_reset_auth_token).and_return(@user)
    end
    describe "トークンが期限切れでない場合" do
      before do
        @user.stub!(:reset_auth_token_expires_at).and_return(Time.now + 1.hour)
      end
      describe "OpenIDのパラメータが存在する場合" do
        describe "identity_urlがポストされた場合" do
          it "OpenID認証処理が開始されること" do
            controller.should_receive(:begin_open_id_authentication)
            get_reset_openid({:openid_url => @identity_url})
          end
        end
        describe "OpenIDのリクエストが成功した場合" do
          before do
            @result = mock('result', :successful? => true)
            @identifier.stub!(:url=)
            @user.stub!(:determination_reset_auth_token)
            controller.should_receive(:authenticate_with_open_id).and_yield(@result, @identity_url)
          end
          describe "OpenID identifierの保存が成功した場合" do
            before do
              @identifier.stub!(:save).and_return(true)
            end
            it "新しく取得したopenid_identifierを設定すること" do
              @identifier.should_receive(:url=).with(@identity_url)
              get_reset_openid({:open_id_complete => "1"})
            end
            it "OpenidIdentifierが保存されること" do
              @identifier.should_receive(:save).and_return(true)
              get_reset_openid({:open_id_complete => "1"})
            end
            it "ログイン画面にリダイレクトされること" do
              get_reset_openid({:open_id_complete => "1"})
              response.should redirect_to(:action => :index)
            end
            it "トークンが初期化されること" do
              @user.should_receive(:determination_reset_auth_token)
              get_reset_openid({:open_id_complete => "1"})
            end
          end
          describe "OpenID identifierの保存が失敗した場合" do
            before do
              @identifier.stub!(:save).and_return(false)
            end
            it "@identifierに値が存在すること" do
              get_reset_openid({:open_id_complete => "1"})
              assigns[:identifier].should == @identifier
            end
            it "reset_openidがrenderされること" do
              get_reset_openid({:open_id_complete => "1"})
              response.should render_template('reset_openid')
            end
          end
        end
        describe "OpenIDのリクエストが失敗した場合" do
          it "エラーとなること" do
            @result = mock('result', :successful? => false)
            controller.should_receive(:authenticate_with_open_id).and_yield(@result, @identity_url)
            get_reset_openid({:open_id_complete => "1"})
            response.should render_template('reset_openid')
            flash[:error].should_not be_nil
          end
        end
      end
      describe "OpenIDのパラメータが存在しない場合" do
        before do
          get_reset_openid
        end
        it "reset_openidがrenderされること" do
          response.should render_template('reset_openid')
        end
        it "@identifierが設定されていること" do
          assigns[:identifier].should_not be_nil
        end
      end
    end
    describe "トークンが期限切れの場合" do
      it "エラーとなること" do
        @user.stub!(:reset_auth_token_expires_at).and_return(Time.now - 1.day)
        get_reset_openid
        validate_error_msg_and_render_reset_openid(response, flash)
      end
    end
  end
  describe "トークンが見つからない場合" do
    it "エラーとなること" do
      User.stub!(:find_by_reset_auth_token)
      get_reset_openid
      validate_error_msg_and_render_reset_openid(response, flash)
    end
  end
  def validate_error_msg_and_render_reset_openid(response, flash)
    response.should redirect_to(:action => :index)
    flash[:error].should_not be_nil
  end
  def get_reset_openid(options = {})
    get :reset_openid, {:code => @reset_token}.merge(options)
  end
end
