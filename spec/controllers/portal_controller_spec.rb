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

require File.dirname(__FILE__) + '/../spec_helper'

describe PortalController, 'GET /index' do
  describe "entrance_next_actionが何もない時" do
    before do
      get :index
    end
    it { response.should render_template('confirm') }
  end
  describe "entrance_next_actionが:account_registrationの場合" do
    before do
      session[:entrance_next_action] = :account_registration
      @user = unused_user_login
      get :index
    end
    it { response.should render_template('account_registration')}
    it { assigns[:user].should be_is_a(User) }
  end
  describe "entrance_next_actionが:registrationの場合" do
    before do
      session[:entrance_next_action] = :registration
    end
    describe '未登録のログインユーザが存在する(正しくsignupしている)場合' do
      before do
        @profiles = []
        @user = unused_user_login
        @user.stub!(:email).and_return("skip@skip.openskip.org")

        get :index
      end
      it { response.should render_template('registration') }
      it "正しいインスタンス変数が設定されていること" do
        assigns[:user].should == @user
        assigns[:profiles].should == @profiles
        assigns[:user_uid].should_not be_nil
        assigns[:user_uid].uid.should == "skip"
      end
    end
    describe '未登録のログインユーザが存在しない(正しくsignup出来ていない or セッション切れ)場合' do
      it 'ユーザ登録が継続できない旨のエラーメッセージが出力されること' do
        get :index
        flash[:error].should_not be_nil
      end
      it 'ログイン画面にリダイレクトされること' do
        get :index
        response.should redirect_to(:controller => 'platform', :action => 'index')
      end
    end
  end
end

# ここでやりたいことは何か?
# 既にUser, UserUidは登録済みだ。
# 1. ユーザ名有効でユーザ名を変更することが出来る。(UserUidを一件作らないといけない。)
# 2. ユーザを活性化しなければいけない。
# 3. 初期アンテナを作成しなければいけない。
# 4. 新しい部署の上書きをしなければいけない。
# 5. 新しいalma_materの上書きをしなければいけない。
# 6. 新しい住所の上書きをしなければいけない。
# 7. 趣味を登録しなければいけない。
describe PortalController, 'POST /apply' do
  before do
    @user = unused_user_login
    @user.stub!(:save!)
    @profiles = (1..2).map{|i| stub_model(UserProfileValue, :save! => true)}
    @user.stub!(:find_or_initialize_profiles).and_return(@profiles)
    UserAccess.stub!(:create!)
    UserMailer::Smtp.stub!(:deliver_sent_signup_confirm)
    @user.stub!(:activate!)
    @user.stub!(:within_time_limit_of_activation_token?)
    SkipEmbedded::InitialSettings['username_use_setting'] = false
    SkipEmbedded::InitialSettings['user_code_format_regex'] = '/a/'
    SkipEmbedded::InitialSettings['login_mode'] = 'password'
    SkipEmbedded::InitialSettings['sha1_digest_key'] = 'digest_key'
  end

  describe '正常に終了する場合' do
    describe 'ユーザ名利用設定がoffの場合' do
      before do
        SkipEmbedded::InitialSettings['username_use_setting'] = false
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
      it "profilesが保存されること" do
        @user.should_receive(:find_or_initialize_profiles).with({"1"=>"ほげ", "2"=>"ふが"}).and_return(@profiles)
        @profiles.each{ |profile| profile.should_receive(:save!) }
        post_apply
      end
      it 'welcomeページにリダイレクトされること' do
        post_apply
        response.should redirect_to(:controller => 'mypage', :action => 'welcome')
      end
    end
    describe 'ユーザ名利用設定がonの場合' do
      before do
        SkipEmbedded::InitialSettings['username_use_setting'] = true
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
      it "profilesが保存されること" do
        @user.should_receive(:find_or_initialize_profiles).with({"1"=>"ほげ", "2"=>"ふが"}).and_return(@profiles)
        @profiles.each{ |profile| profile.should_receive(:save!) }
        post_apply
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
      SkipEmbedded::InitialSettings['user_code_format_regex'] = '/a/'
    end
    describe 'ユーザ名利用設定がoffの場合' do
      before do
        SkipEmbedded::InitialSettings['username_use_setting'] = false
      end
      it '登録ページに遷移すること' do
        post_apply
        response.should render_template('portal/registration')
      end
      it "適切なインスタンス変数が設定されていること" do
        post_apply
        assigns[:user].should_not be_nil
        assigns[:user].status.should == 'UNUSED'
        assigns[:profiles].should_not be_nil
        assigns[:user_uid].should be_nil
      end
      it "２つのプロフィールにエラーが設定されている場合、２つのバリデーションエラーが設定されること" do
        errors = mock('errors', :full_messages => ["バリデーションエラーです"])
        @profiles.map do |profile|
          profile.stub!(:valid?).and_return(false)
          profile.stub!(:errors).and_return(errors)
        end

        post_apply
        assigns[:error_msg].grep("バリデーションエラーです").size.should == 2
      end
    end
    describe 'ユーザ名利用設定がonの場合' do
      before do
        SkipEmbedded::InitialSettings['username_use_setting'] = true
      end
      it '登録ページに遷移すること' do
        post_apply
        response.should render_template('portal/registration')
      end
      it "適切なインスタンス変数が設定されていること" do
        post_apply
        assigns[:user].should_not be_nil
        assigns[:user].status.should == 'UNUSED'
        assigns[:profiles].should_not be_nil
        assigns[:user_uid].should_not be_nil
      end
    end
  end

  def verify_save_user
    @user.should_receive(:attributes=)
    @user.should_receive(:status=).with('ACTIVE')
    @user.should_receive(:save!)
    @user.should_receive(:activate!)
    controller.should_receive(:current_user).and_return(@user)
    post_apply
  end

  def post_apply
    post :apply, {"user"=>{:password => "password", :password_confirmation => "password_confirmation", "email"=>"example@skip.org", "section"=>"開発"}, "profile_value"=>{"1"=>"ほげ", "2"=>"ふが"}, "user_uid"=>{"uid"=>"hogehoge"} }
  end
end

describe PortalController, "#registration" do
  before do
    SkipEmbedded::InitialSettings['login_mode'] = 'rp'
    SkipEmbedded::InitialSettings['fixed_op_url'] = nil
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
      @user = stub_model(User, :code => @code)
      @user.stub!(:user_uids).and_return([@user_uid])
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
