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
  fixtures :users, :user_uids
  before(:each) do
    @user = users(:a_user)
    ActionMailer::Base.deliveries.clear
    session[:user_code] = @user.code
  end

  describe "POST /mypage/apply_email" do
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
    before do
      @url = 'http://example.com'

      @openid_identifier = stub_model(OpenidIdentifier)
      @openid_identifiers = []
      @openid_identifiers.should_receive(:<<)
      OpenidIdentifier.should_receive(:new).and_return(@openid_identifier)

      @account = stub_model(Account)
      @account.stub!(:openid_identifiers).and_return(@openid_identifiers)
      Account.should_receive(:find_by_code).with(@user.code).and_return(@account)
    end

    describe '保存に成功した場合' do
      before do
        @openid_identifier.should_receive(:url=).with(@url)
        @openid_identifier.should_receive(:save).and_return(true)

        post :apply_ident_url, :openid_identifier => {:url => @url}
      end

      it { response.should be_redirect  }
      it { flash[:notice].should_not be_nil }
    end

    describe '保存に失敗した場合' do
      before do
        @openid_identifier.should_receive(:url=).with(@url)
        @openid_identifier.should_receive(:save).and_return(false)
        @openid_identifiers.should_receive(:reload).and_return(@openid_identifiers)

        post :apply_ident_url, :openid_identifier => {:url => @url}
      end

      it { response.should be_success }
      it { assigns[:openid_identifiers].should_not be_nil }
      it { response.should render_template('mypage/_manage_openid') }
      it { flash[:notice].should be_nil }
    end

    describe 'パラメータが不足していた場合' do
      before do
        @openid_identifiers.should_receive(:reload).and_return(@openid_identifiers)

        post :apply_ident_url
      end

      it { assigns[:openid_identifiers].should_not be_nil }
      it { response.should be_success }
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
      @account = mock_model(Account)
      @openid_identifier = mock_model(OpenidIdentifier)
      @openid_identifier.stub!(:account).and_return(@account)
    end

    describe "登録されているOpenID URLの場合" do
      before do
        @account.should_receive(:code).and_return('100001')
        @openid_identifier.should_receive(:destroy)
        OpenidIdentifier.should_receive(:find_by_url).with(@url).and_return(@openid_identifier)
        post :delete_ident_url, :ident_url => @url
      end

      it { response.should be_redirect }
      it { flash[:notice].should == "OpenID URLを削除しました。" }
    end

    describe "他人に関連付けられているURLの場合" do
      before do
        @account.should_receive(:code).and_return('222222')
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
