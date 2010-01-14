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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::UserProfilesController, "GET /edit" do
  before do
    admin_login

    @user = mock_model(User, :name => "a user")
    Admin::User.stub!(:find).and_return(@user)
    @profiles = (1..5).map{|i| mock_model(UserProfileValue, :user => @user, :value => "value#{i}")}
    @user.stub!(:user_profile_values).and_return(@profiles)
  end
  it "リクエストが成功すること" do
    get :edit

    response.should render_template("admin/user_profiles/edit")
  end
  it "ユーザが検索されること" do
    Admin::User.should_receive(:find).with(@user.id.to_s).and_return(@user)

    get :edit, :user_id => @user.id
  end
  it "@profilesが設定されていること" do
    get :edit

    assigns[:profiles].should == @profiles
  end
end

describe Admin::UserProfilesController, "PUT /update" do
  before do
    admin_login

    @user = mock_model(User, :name => "a user")
    Admin::User.stub!(:find).and_return(@user)
    @profiles = (1..5).map{|i| mock_model(UserProfileValue, :user => @user, :value => "value#{i}", :save! => true, :errors => mock('errors', :full_messages => []))}
    @user.stub!(:find_or_initialize_profiles).and_return(@profiles)
    @profile_value = { "1" => "value1", "2" => "value2" }
  end
  describe "saveがすべて成功する場合" do
    it "リダイレクトされること" do
      post_update
      response.should be_redirect
    end
    it "パラメータが find_or_initialize_profiles に渡されること" do
      @user.should_receive(:find_or_initialize_profiles).with(@profile_value).and_return(@profiles)
      post_update
    end
    it "すべてのprofileがsaveされること" do
      @profiles.each{|profile| profile.should_receive(:save!)}
      post_update
    end
    it "更新されたというflashメッセージが登録されていること" do
      post_update
      flash[:notice].should == "user profile was successfully updated."
    end
  end
  describe "saveに失敗する場合" do
    before do
      @profiles[3].stub!(:save!).and_raise(mock_record_invalid)
      @profiles[3].stub!(:errors).and_return(mock('errors', :full_messages => ["validation error3"]))
      @profiles[4].stub!(:errors).and_return(mock('errors', :full_messages => ["validation error4"]))
      @profiles.each{|profile| profile.stub!(:valid?)}
    end
    it "editをレンダリングすること" do
      post_update
      response.should render_template("admin/user_profiles/edit")
    end
    it "@profilesが設定されていること" do
      post_update
      assigns[:profiles].should == @profiles
    end
    it "エラーメッセージが設定されること" do
      post_update
      assigns[:error_msg].should == ["validation error3", "validation error4"]
    end
  end
  def post_update
    post :update, :user_id => @user.id, :profile_value => @profile_value
  end
end
