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

describe PortalController, 'GET /index' do
  before do
    @user = unused_user_login
  end
  describe "entrance_next_actionが何もない時" do
    before do
      get :index
    end
    it { response.should render_template('confirm') }
  end

  describe "entrance_next_actionが:registrationの場合" do
    before do
      session[:entrance_next_action] = :registration

      @profile = stub_model(UserProfile, :email => "skip@skip.openskip.org")
      @user = unused_user_login
      @user.stub!(:user_profile).and_return(@profile)

      get :index
    end
    it { response.should render_template('registration') }
    it "正しいインスタンス変数が設定されていること" do
      assigns[:user].should == @user
      assigns[:profile].should_not be_nil
      assigns[:user_uid].should_not be_nil
      assigns[:user_uid].uid.should == "skip"
    end
  end
  describe "entrance_next_actionが:account_registrationの場合" do
    before do
      session[:entrance_next_action] = :account_registration
      get :index
    end
    it { response.should render_template('account_registration')}
    it { assigns[:user].should be_is_a(User) }
  end
end

# ここでやりたいことは何か?
# 既にUser, UserProfile, UserUidは登録済みだ。
# 1. ユーザ名有効でユーザ名を変更することが出来る。(UserUidを一件作らないといけない。)
# 2. ユーザを活性化しなければいけない。
# 3. 初期アンテナを作成しなければいけない。
# 4. 新しい部署の上書きをしなければいけない。
# 5. 新しいalma_materの上書きをしなければいけない。
# 6. 新しい住所の上書きをしなければいけない。
# 7. 趣味を登録しなければいけない。
# 8. wite_profileでdisclosureを上書きしなければいけない。
describe PortalController, 'POST /apply' do
  before do
    @profile = stub_model(UserProfile)
    @profile.stub!(:attributes_for_registration)
    @profile.stub!(:save!)
    @user = unused_user_login
    @user.stub!(:save!)
    @user.stub!(:user_profile).and_return(@profile)
    @user.stub!(:create_initial_entry)
    @antenna = stub_model(Antenna)
    @antenna.stub!(:save!)
    Antenna.stub!(:create_initial!).and_return(@antenna)
    UserAccess.stub!(:create!)
    UserMailer.stub!(:deliver_sent_signup_confirm)
    @user.stub!(:activate!)
    @user.stub!(:within_time_limit_of_activation_token?)
    INITIAL_SETTINGS['username_use_setting'] = false
  end

  describe '正常に終了する場合' do
    describe 'ユーザ名利用設定がoffの場合' do
      before do
        INITIAL_SETTINGS['username_use_setting'] = false
      end
      it 'UserUidが保存されないこと' do
        @user_uid = stub_model(UserUid)
        @user_uid.should_not_receive(:save!)
        @user_uids = mock('user_uids', :build => @user_uid)
        @user.stub!(:user_uids).and_return(@user_uids)
        @user.should_receive(:code).and_return("111111")
        post_apply
      end
      it 'Userが保存されること' do
        verify_save_user
      end
      it 'Profileが保存されること' do
        verify_save_user_profile
      end
      it 'welcomeページにリダイレクトされること' do
        post_apply
        response.should redirect_to(:controller => 'mypage', :action => 'welcome')
      end
    end
    describe 'ユーザ名利用設定がonの場合' do
      before do
        INITIAL_SETTINGS['username_use_setting'] = true
      end
      it 'UserUidが保存されること' do
        @user_uid = stub_model(UserUid)
        @user_uid.should_receive(:save!)
        @user_uids = mock('user_uids', :build => @user_uid)
        @user.should_receive(:user_uids).and_return(@user_uids)
        @user.should_receive(:code).and_return("111111")
        post_apply
      end
      it 'Userが保存されること' do
        verify_save_user
      end
      it 'Profileが保存されること' do
        verify_save_user_profile
      end
      it 'welcomeページにリダイレクトされること' do
        post_apply
        response.should redirect_to(:controller => 'mypage', :action => 'welcome')
      end
    end
    describe 'アクティベート機能が無効の場合' do
      before do
        @user.should_receive(:within_time_limit_of_activation_token?).and_return(false)
      end
      it 'UserのstatusがACTIVEに設定されて保存されること' do
        @user.should_receive(:status=).with('ACTIVE')
        @user.save!
        post_apply
      end
      it 'activateされること' do
        @user.should_receive(:activate!)
        post_apply
      end
      it 'welcomeページにリダイレクトされること' do
        post_apply
        response.should redirect_to(:controller => 'mypage', :action => 'welcome')
      end
    end
    describe 'アクティベート機能が有効の場合' do
      before do
        @user.should_receive(:within_time_limit_of_activation_token?).and_return(true)
      end
      it 'crypted_passwordのクリアが行われること' do
        # passwordの必須チェックに引っ掛けるため。もっと別の対応をしたい所
        @user.should_receive(:crypted_password=).with(nil)
        post_apply
      end
      it 'パスワードの設定が行われること' do
        @user.should_receive(:password=).at_least(:once)
        @user.should_receive(:password_confirmation=).at_least(:once)
        post_apply
      end
      it 'UserのstatusがACTIVEに設定されて保存されること' do
        @user.should_receive(:status=).with('ACTIVE')
        @user.save!
        post_apply
      end
      it 'activateされること' do
        @user.should_receive(:activate!)
        post_apply
      end
      it 'welcomeページにリダイレクトされること' do
        post_apply
        response.should redirect_to(:controller => 'mypage', :action => 'welcome')
      end
    end
  end

  describe '異常終了する場合' do
    before do
      @user.stub!(:save!).and_raise(mock_record_invalid)
      controller.stub!(:current_user).and_return(@user)
    end
    describe 'ユーザ名利用設定がoffの場合' do
      before do
        INITIAL_SETTINGS['username_use_setting'] = false
      end
      it '登録ページに遷移すること' do
        post_apply
        response.should render_template('portal/registration')
      end
      it "適切なインスタンス変数が設定されていること" do
        post_apply
        assigns[:user].should_not be_nil
        assigns[:profile].should_not be_nil
        assigns[:user_uid].should be_nil
      end
    end
    describe 'ユーザ名利用設定がonの場合' do
      before do
        INITIAL_SETTINGS['username_use_setting'] = true
      end
      it '登録ページに遷移すること' do
        post_apply
        response.should render_template('portal/registration')
      end
      it "適切なインスタンス変数が設定されていること" do
        post_apply
        assigns[:user].should_not be_nil
        assigns[:profile].should_not be_nil
        assigns[:user_uid].should_not be_nil
      end
    end
  end

  def verify_save_user
    @user.should_receive(:attributes=)
    @user.should_receive(:save!)
    @user.should_receive(:activate!)
    controller.should_receive(:current_user).and_return(@user)
    post_apply
  end

  def verify_save_user_profile
    @profile.should_receive(:attributes_for_registration)
    @profile.should_receive(:save!)
    post_apply
  end

  def post_apply
    post :apply, {"user"=>{:password => "password", :password_confirmation => "password_confirmation"},
                  "profile"=>{"email"=>"example@skip.org", "extension"=>"000000", "self_introduction"=>"00000",
                    "section"=>"開発", "birth_month"=>"1", "join_year"=>"2008", "blood_type"=>"1", "address_1"=>"1",
                    "alma_mater"=>"非公開", "birth_day"=>"1", "gender_type"=>"1", "address_2"=>"非公開", "introduction"=>"",
                    "hometown"=>"1"},
                  "user_uid"=>{"uid"=>"hogehoge"},
                  "new_address_2"=>"", "write_profile"=>"true", "new_section"=>"営業", "new_alma_mater"=>"" }
  end
end

describe PortalController, "#registration" do
  before do
    INITIAL_SETTINGS['login_mode'] = 'rp'
    INITIAL_SETTINGS['fixed_op_url'] = nil
  end
  describe "session[:identity_url]が空の場合" do
    before do
      session[:identity_url] = nil

      post :registration
    end
    it { response.should redirect_to(:controller => :platform, :action => :index)}
  end
  describe "session[:identity_url]に値が入っている場合" do
    before do
      @openid_url = 'http://www.openskip.org/a_user/'
      session[:identity_url] = @openid_url

      @code = 'hoge'
      @params = { "code" => @code, "email" => 'email@openskip.org', "name" => 'SKIP君'}

      @user_uid = stub_model(UserUid)
      @user_profile = stub_model(User)
      @user = stub_model(User, :code => @code)
      @user.stub!(:user_uids).and_return([@user_uid])
      @user.stub!(:user_profile).and_return(@user_profile)
      User.should_receive(:create_with_identity_url).with(@openid_url, @params).and_return(@user)
    end
    describe "保存が成功する場合" do
      before do
        @user.stub!(:valid?).and_return(true)
        controller.should_receive(:current_user=).with(@user)

        post :registration, :user => @params
      end
      it { response.should redirect_to({ :action => :index }) }
      it "session[:identity_url]が削除されること" do
        session[:identity_url].should be_nil
      end
    end
    describe "保存が失敗する場合" do
      before do
        @user.stub!(:valid?).and_return(false)

        post :registration, :user => @params
      end
      it { response.should render_template('portal/account_registration') }
      it { assigns[:user].should == @user }
    end
  end
end
