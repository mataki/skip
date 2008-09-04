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

describe MypageController do
  before(:each) do
    @user = user_login
    ActionMailer::Base.deliveries.clear
  end

  describe "POST /mypage/apply_email" do
    before do
      session[:user_id] = 1
    end
    it "should be successful" do
      post :apply_email, {:applied_email => {:email => SkipFaker.email}}
      response.should be_success
      assigns[:menu].should == "manage_email"
      assigns[:user].should == @user
      AppliedEmail.find_by_id(assigns(:applied_email).id).should_not be_nil
      ActionMailer::Base.deliveries.first.body.should match(/http:\/\/test\.host\/mypage\/update_email\/.*/m)
    end
  end

  describe "POST /mypage/apply_ident_url" do
    describe '新規登録の場合' do
      before do
        @url = 'http://example.com'

        @user = user_login

        @openid_identifier = stub_model(OpenidIdentifier, :user_id => @user.id, :url => @url)
        @openid_identifier.stub!(:url=).with(@url)

        @openid_identifiers = mock('openid_identifiers')
        @openid_identifiers.stub!(:empty?).and_return(true)
        @openid_identifiers.stub!(:build).and_return(@openid_identifier)

        @user.stub!(:openid_identifiers).and_return(@openid_identifiers)
      end

      describe '保存に成功した場合' do
        before do
          @openid_identifier.should_receive(:save).and_return(true)
          post :apply_ident_url, :openid_identifier => {:url => @url}
        end

        it { response.should be_redirect  }
        it { flash[:notice].should_not be_nil }
      end

      describe '保存に失敗した場合' do
        before do
          @openid_identifier.should_receive(:save).and_return(false)

          post :apply_ident_url, :openid_identifier => {:url => @url}
        end

        it { assigns[:openid_identifier].should_not be_nil }
        it { response.should render_template('mypage/_manage_openid') }
        it { flash[:notice].should be_nil }
      end
    end
    describe '更新の場合' do
      before do
        @user = user_login

        @openid_identifier = stub_model(OpenidIdentifier, :user_id => @user.id)

        @openid_identifiers = mock('openid_identifiers')
        @openid_identifiers.stub!(:empty?).and_return(false)
        @openid_identifiers.stub!(:first).and_return(@openid_identifier)

        @user.stub!(:openid_identifiers).and_return(@openid_identifiers)
      end
      describe '保存に成功した場合' do
        before do
          @url = 'http://example.com'

          @openid_identifier.should_receive(:url).and_return(@url)
          @openid_identifier.should_receive(:url=).with(@url)
          @openid_identifier.should_receive(:save).and_return(true)

          post :apply_ident_url, :openid_identifier => {:url => @url}
        end

        it { response.should be_redirect }
        it { flash[:notice].should_not be_nil }
      end
      describe '保存に失敗した場合' do
        before do
          @url = 'http://example.com'

          @openid_identifier.should_receive(:url).and_return(@url)
          @openid_identifier.should_receive(:url=).with(@url)
          @openid_identifier.should_receive(:save).and_return(false)

          post :apply_ident_url, :openid_identifier => {:url => @url}
        end

        it { response.should render_template('mypage/_manage_openid') }
        it { assigns[:openid_identifier].should_not be_nil }
      end

      describe 'URLが空の場合' do
        before do
          @url = ''
          @openid_identifier.stub!(:url=).with(@url)

          @openid_identifier.should_receive(:destroy)

          post :apply_ident_url, :openid_identifier => {:url => @url}
        end

        it { response.should be_redirect }
        it { flash[:notice].should_not be_nil}
      end
    end
  end

  describe "GET /mypage/apply_ident_url" do
    before do
      get :apply_ident_url
    end
    it { response.should redirect_to(:action => :index)}
  end

  describe "POST /mypage/delete_ident_url" do
    before do
      @url = 'http://hoge.example.com/'
      @user = mock_model(User)
      @openid_identifier = mock_model(OpenidIdentifier)
      @openid_identifier.stub!(:user).and_return(@user)
    end

    describe "登録されているOpenID URLの場合" do
      before do
        session[:user_code] = '100001'
        @user.should_receive(:code).and_return('100001')
        @openid_identifier.should_receive(:destroy)
        OpenidIdentifier.should_receive(:find_by_url).with(@url).and_return(@openid_identifier)
        post :delete_ident_url, :ident_url => @url
      end

      it { response.should be_redirect }
      it { flash[:notice].should == "OpenID URLを削除しました。" }
    end

    describe "他人に関連付けられているURLの場合" do
      before do
        @user.should_receive(:code).and_return('222222')
        @openid_identifier.should_not_receive(:destroy)
        OpenidIdentifier.should_receive(:find_by_url).with(@url).and_return(@openid_identifier)
        post :delete_ident_url, :ident_url => @url
      end

      it { response.should be_redirect }
      it { flash[:notice].should == "そのOpenID URLは登録されていません。" }
    end

    describe "登録されているURLでなかった場合" do
      before do
        OpenidIdentifier.should_receive(:find_by_url).with(@url).and_return(nil)
        post :delete_ident_url, :ident_url => @url
      end

      it { response.should be_redirect }
      it { flash[:notice].should == "そのOpenID URLは登録されていません。" }
    end
  end
end

describe MypageController, 'POST #update_profile' do
  before do
    @user = user_login
    @user.stub!(:update_attributes)
    @profile = stub_model(UserProfile)
    @profile.stub!(:errors).and_return([])
    @user.stub!(:update_profile).and_return(@profile)
  end
  describe '保存に成功する場合' do
    before do
      @user.should_receive(:update_attributes).and_return(true)
      post :update_profile, {"new_address_2"=>"", "commit"=>"保存", "profile"=>{"birth_month"=>"1", "join_year"=>"2008", "blood_type"=>"1", "extension"=>"111111", "address_1"=>"1", "alma_mater"=>"あああ", "birth_day"=>"1", "gender_type"=>"1", "self_introduction"=>"よろしく", "address_2"=>"あははははははは", "introduction"=>"", "section"=>"TC", "hometown"=>"1"}, "write_profile"=>"true", "action"=>"update_profile", "new_alma_mater"=>"", "controller"=>"mypage", "new_section"=>"", "hobbies"=>["習いごと", "語学", "マンガ", "美容"]}
    end
    it {assigns[:user].should_not be_nil}
    it {assigns[:profile].should_not be_nil}
    it {assigns[:error_msg].should be_nil}
    it {response.should be_redirect}
  end
  describe '保存に失敗する場合' do
    it '保存に失敗すること'
  end
end
