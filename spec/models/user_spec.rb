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

describe User," is a_user" do
  fixtures :users, :user_accesses, :user_uids
  before(:each) do
    @user = users(:a_user)
  end

  it "get uid and name by to_s" do
    @user.to_s.should == "uid:#{@user.uid}, name:#{@user.name}"
  end

  it "get symbol_id" do
    @user.symbol_id.should == "a_user"
  end

  it "get symbol" do
    @user.symbol.should == "uid:a_user"
  end

  it "get before_access" do
    @user.before_access.should == "1 日以内"
  end

  it "set mark_track" do
    lambda {
      @user.mark_track(users(:a_group_joined_user).id)
    }.should change(Track, :count).by(1)
  end
end

describe User, "#before_save" do
  before do
    @user = new_user
  end

  it "保存する際はパスワードが暗号化される" do
    @user.save.should be_true
    @user.crypted_password.should == User.encrypt('password')
  end

  it "パスワード以外の変更で再度保存される場合はパスワードは変更されない" do
    @user.save
    # password_required?の条件でpasswordが空になる必要があるためロードし直す
    @user = User.find_by_id(@user.id)

    @user.should_not_receive(:crypted_password=)
    @user.name = 'fuga'
    @user.send(:password_required?).should be_false
    @user.save
  end
end

describe User, '#change_password' do
  before do
    @user = create_user
    @old_password = @user.password
    @new_password = 'hogehoge'

    @params = { :old_password => @old_password, :password => @new_password, :password_confirmation => @new_password }
  end
  describe "前のパスワードが正しい場合" do
    describe '新しいパスワードが入力されている場合' do
      it 'パスワードが変更されること' do
        lambda do
          @user.change_password @params
        end.should change(@user, :crypted_password)
      end
    end
    describe '新しいパスワードが入力されていない場合' do
      before do
        @params[:password] = ''
        @user.change_password @params
      end
      it { @user.errors.full_messages.size.should == 1 }
    end
  end
  describe "前のパスワードが間違っている場合" do
    before do
      @params[:old_password] = 'fugafuga'
      @user.change_password @params
    end
    it { @user.errors.full_messages.size.should == 1 }
  end
end

describe User, ".new_with_identity_url" do
  describe "正しく保存される場合" do
    before do
      @identity_url = "http://test.com/identity"
      @params = { :code => 'hoge', :name => "ほげ ふが", :email => 'hoge@hoge.com' }
      @user = User.new_with_identity_url(@identity_url, @params)
    end

    it { @user.should be_valid }
    it { @user.should be_is_a(User) }
    it { @user.openid_identifiers.should_not be_nil }
    it { @user.openid_identifiers.map{|i| i.url}.should be_include(@identity_url) }
  end
  describe "バリデーションエラーの場合" do
    before do
      @identity_url = "http://test.com/identity"
      @params = { :code => 'hoge', :name => '', :email => "" }
      @user = User.new_with_identity_url(@identity_url, @params)
    end
    it { @user.should_not be_valid }
    it "エラーがUserUidとUserProfileに設定されていること" do
      @user.valid?
      @user.errors.full_messages.size.should == 2
    end
    it { @user.user_profile.should_not be_nil }
  end
end

describe User, ".create_with_identity_url" do
  before do
    @identity_url = "http://test.com/identity"
    @params = { :code => 'hoge', :name => "ほげ ふが", :email => 'hoge@hoge.com' }

    @user = mock_model(User)
    User.should_receive(:new_with_identity_url).and_return(@user)

    @user.should_receive(:save)
  end
  it { User.create_with_identity_url(@identity_url, @params).should be_is_a(User) }
end

describe User, ".auth" do
  describe "ログインID・パスワードが正しい場合" do
    before do
      @password = 'password'
      @user = mock_model(User)
      @user.stub!(:crypted_password).and_return(User.encrypt(@password))
      User.should_receive(:find_by_code).and_return(@user)
    end
    it { User.auth('code', @password).should == @user }
  end
  describe "ユーザは存在するが、パスワードは正しくない場合" do
    before do
      @user = mock_model(User)
      @user.stub!(:crypted_password).and_return('hogehoge')
      User.should_receive(:find_by_code).and_return(@user)
    end
    it { User.auth('code', 'password').should be_nil }
  end
  describe "指定のユーザが存在しない場合" do
    before do
      User.should_receive(:find_by_code).and_return(nil)
    end
    it { User.auth('code', 'password').should be_nil }
  end
end

describe User, "#delete_auth_tokens" do
  before do
    @user = create_user
    @user.remember_token = "remember_token"
    @user.remember_token_expires_at = Time.now
    @user.auth_session_token = "auth_session_token"
    @user.save

    @user.delete_auth_tokens!
  end
  it "すべてのトークンが削除されていること" do
    @user.remember_token.should be_nil
    @user.remember_token_expires_at.should be_nil
    @user.auth_session_token.should be_nil
  end
end

describe User, "#update_auth_session_token" do
  before do
    @user = create_user
    @auth_session_token = User.make_token
    User.stub!(:make_token).and_return(@auth_session_token)
  end
  it "トークンが保存されること" do
    @user.update_auth_session_token!
    @user.auth_session_token.should == @auth_session_token
  end
  it "トークンが返されること" do
    @user.update_auth_session_token!.should == @auth_session_token
  end
end

def new_user options = {}
  User.new({ :name => 'ほげ ほげ', :password => 'password', :password_confirmation => 'password'}.merge(options))
end

