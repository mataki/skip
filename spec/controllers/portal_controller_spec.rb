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
    it { response.should be_success }
    it { response.should render_template('confirm') }
  end

  describe "entrance_next_actionが:registrationの場合" do
    before do
      session[:entrance_next_action] = :registration
      get :index
    end
    it { response.should be_success }
    it { response.should render_template('registration') }
    it { assigns[:user].should == @user }
    it { assigns[:profile].should_not be_nil }
    it { assigns[:user_uid].should_not be_nil }
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
# 1. ニックネーム有効でニックネームを変更することが出来る。(UserUidを一件作らないといけない。)
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
  end
  describe '正常に動作する場合' do
    before do
      @profile.should_receive(:attributes_for_registration)
      @profile.should_receive(:save!)

      @user.should_receive(:status=).with('ACTIVE')
      @user.should_receive(:attributes=).with(params[:user])
      @user.should_receive(:save!)
      controller.stub!(:current_user).and_return(@user)

      post :apply, {"profile"=>{"email"=>"example@skip.org", "extension"=>"000000", "introduction"=>"00000", "section"=>"開発", "birth_month"=>"1", "join_year"=>"2008", "blood_type"=>"1", "address_1"=>"1", "alma_mater"=>"非公開", "birth_day"=>"1", "gender_type"=>"1", "address_2"=>"非公開", "introduction"=>"", "hometown"=>"1"},
        "user_uid"=>{"uid"=>"hogehoge"},
        "new_address_2"=>"", "write_profile"=>"true", "new_section"=>"営業", "new_alma_mater"=>"" }
    end

    it { response.should be_redirect }
    it { assigns[:user].should_not be_nil }
    it { assigns[:profile].should_not be_nil }
    it { assigns[:user_uid].should_not be_nil }
  end

  describe '保存に失敗する場合' do
    before do
      INITIAL_SETTINGS.stub!('[]').with('nickname_use_setting').and_return(false)
      @user.should_receive(:save!).and_raise(mock_record_invalid)
      controller.stub!(:current_user).and_return(@user)
      post :apply, {"profile"=>{"email"=>"example@skip.org", "extension"=>"000000", "introduction"=>"00000", "section"=>"開発", "birth_month"=>"1", "join_year"=>"2008", "blood_type"=>"1", "address_1"=>"1", "alma_mater"=>"非公開", "birth_day"=>"1", "gender_type"=>"1", "address_2"=>"非公開", "introduction"=>"", "hometown"=>"1"},
        "user_uid"=>{"uid"=>"hogehoge"},
        "new_address_2"=>"", "write_profile"=>"true", "new_section"=>"営業", "new_alma_mater"=>"" }
    end
    it {response.should be_success}
    it {response.should render_template('portal/registration')}
  end
end

describe PortalController, "#registration" do
  before do
    ENV['FREE_OP'] = "ON"
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

      @user = mock_model(User, :code => @code)
      User.should_receive(:create_with_identity_url).with(@openid_url, @params).and_return(@user)
    end
    describe "保存が成功する場合" do
      before do
        @user.stub!(:valid?).and_return(true)

        post :registration, :user => @params
      end
      it { response.should redirect_to({ :action => :index }) }
      it { session[:user_code].should == @user.code }
      it { session[:identity_url].should be_nil }
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
