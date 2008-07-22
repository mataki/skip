# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008  TIS Inc.
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
      @account = stub_model(Account)
      Account.should_receive(:find_by_code).with(@user.code).and_return(@account)
    end

    describe '保存に成功した場合' do
      before do
        @account.should_receive(:ident_url=).with('http://example.com/')
        @account.should_receive(:save).and_return(true)

        post :apply_ident_url, :account => {:ident_url => 'http://example.com/'}
      end

      it { response.should be_redirect  }
      it { flash[:notice].should_not be_nil }
    end

    describe '保存に失敗した場合' do
      before do
        @account.should_receive(:ident_url=).with('http://example.com/')
        @account.should_receive(:save).and_return(false)
        post :apply_ident_url, :account => {:ident_url => 'http://example.com/'}
      end

      it { response.should be_success }
      it { response.should render_template('mypage/_manage_openid') }
      it { flash[:notice].should be_nil }
    end

    describe 'パラメータが不足していた場合' do
      before do
        post :apply_ident_url
      end

      it { response.should be_success }
    end

  end

  describe "GET /mapage/apply_ident_url" do
    before do
      get :apply_ident_url
    end
    it { response.should redirect_to(:action => :index)}
  end
end
