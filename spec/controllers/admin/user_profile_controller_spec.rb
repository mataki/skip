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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::UserProfilesController, 'GET /admin_user_user_profile' do
  before do
    admin_login
    @user = mock(Admin::User, :name => 'name')
    @user_profile = mock(Admin::UserProfile)
    @user.should_receive(:user_profile).and_return(@user_profile)
    Admin::User.should_receive(:find).and_return(@user)
    get :show
  end
  it {assigns[:user].should == @user}
  it {assigns[:user_profile].should == @user_profile}
  it {response.should be_success}
end

describe Admin::UserProfilesController, 'GET /edit_admin_user_user_profile' do
  before do
    admin_login
    @user = mock(Admin::User, :name => 'name')
    @user_profile = mock(Admin::UserProfile)
    @user.should_receive(:user_profile).and_return(@user_profile)
    Admin::User.should_receive(:find).and_return(@user)
    get :edit
  end
  it {assigns[:user].should == @user}
  it {assigns[:user_profile].should == @user_profile}
end

describe Admin::UserProfilesController, 'PUT /edit_admin_user_user_profile' do
  before do
    admin_login
    @user = mock(Admin::User, :name => 'name')
    @user_profile = mock(Admin::UserProfile)
    @user.should_receive(:user_profile).and_return(@user_profile)
    Admin::User.should_receive(:find).and_return(@user)
  end
  describe '保存に成功する場合' do
    before do
      @user_profile.should_receive(:update_attributes).and_return(true)
      post :update
    end
    it {flash[:notice].should_not be_nil}
    it {assigns[:user].should == @user}
    it {assigns[:user_profile].should == @user_profile}
  end
  describe '保存に失敗する場合' do
    before do
      @user_profile.should_receive(:update_attributes).and_return(false)
      post :update
    end
    it {assigns[:user].should == @user}
    it {assigns[:user_profile].should == @user_profile}
  end
end
