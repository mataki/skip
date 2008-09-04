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

describe Admin::UsersController, 'GET /new' do
  before do
    admin_login
  end
  it 'UnknownActionになること' do
    lambda do
      get :new
    end.should raise_error(ActionController::UnknownAction)
  end
end

describe Admin::UsersController, 'POST /create' do
  before do
    admin_login
  end
  it 'UnknownActionになること' do
    lambda do
      post :create
    end.should raise_error(ActionController::UnknownAction)
  end
end

describe Admin::UsersController, 'GET /first' do
  describe '有効なactivation_codeの場合' do
    before do
      controller.should_receive(:valid_activation_code?).and_return(true)
      get :first
    end
    it {response.should be_success}
  end
end

describe Admin::UsersController, 'POST /first' do
  describe '有効なactivation_codeの場合' do
    before do
      controller.stub!(:valid_activation_code?).and_return(true)
      @user = stub_model(User)
      @user_profile = stub_model(UserProfile)
      @user_uid = stub_model(UserUid)
      @activation = stub_model(Activation)
    end
    describe '管理者ユーザの登録に成功する場合' do
      it 'Userが作成されること' do
        @user.should_receive('admin=').with(true)
        @user.should_receive('status=').with('ACTIVE')
        @user.should_receive(:save!)
        User.should_receive(:new).and_return(@user)
        @user_profile.should_receive('disclosure=').with(true)
        UserProfile.should_receive(:new).and_return(@user_profile)
        UserUid.should_receive(:new).and_return(@user_uid)
        @activation.should_receive(:update_attributes).with({:code => nil})
        Activation.should_receive(:find_by_code).and_return(@activation)
        post :first, {:user => {"name"=>"管理者", "password_confirmation"=>"[FILTERED]", "password"=>"[FILTERED]"}, :user_profile => {"email"=>"admin@skip.org", "section"=>"管理部"}, :user_uid => {:uid => 'admin'}}
      end
      it {response.code.should be_nil}
    end
    describe '管理者ユーザの登録に失敗する場合' do
      before do
        @user.should_receive(:save!).and_raise(mock_record_invalid)
        User.should_receive(:new).and_return(@user)
        post :first, :user_uid => {}
      end
      it {response.should be_success}
    end
  end
  describe '無効なactivation_codeの場合' do
    before do
      controller.should_receive(:valid_activation_code?).and_return(false)
      post :first
    end
    it {response.code.should == '403'}
  end
end

describe Admin::UsersController, '.valid_activation_code?' do
  before do
    @code = '1234'
  end
  describe 'codeがnilの場合' do
    before do
      @code = nil
      Activation.should_not_receive(:find_by_code)
    end
    it {controller.send(:valid_activation_code?, @code).should be_false}
  end
  describe '指定されたcodeがActivationテーブルに登録されている場合' do
    before do
      Activation.should_receive(:find_by_code).and_return(mock_model(Activation))
    end
    it {controller.send(:valid_activation_code?, @code).should be_true}
  end
  describe '指定されたcodeがActivationテーブルに登録されていない場合' do
    before do
      Activation.should_receive(:find_by_code).and_return(nil)
    end
    it {controller.send(:valid_activation_code?, @code).should be_false}
  end
end
