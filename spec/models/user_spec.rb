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

describe User, '#groups' do
  before do
    @user = create_user
    @group = create_group
    group_participation = GroupParticipation.create!(:user_id => @user.id, :group_id => @group.id)
  end
  it '一件のグループが取得できること' do
    @user.groups.size.should == 1
  end
  describe 'グループを論理削除された場合' do
    before do
      @group.logical_destroy
    end
    it 'グループが取得できないこと' do
      @user.groups.size.should == 0
    end
  end
end

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
    @user.before_access.should == "Within 1 day"
  end

  it "set mark_track" do
    lambda {
      @user.mark_track(users(:a_group_joined_user).id)
    }.should change(Track, :count).by(1)
  end
end

describe User, 'validation' do
  describe 'email' do
    before do
      @user = new_user(:email => 'skip@example.org')
      @user.save!
    end
    it 'ユニークであること' do
      new_user(:email => 'skip@example.org').valid?.should be_false
      # 大文字小文字が異なる場合もNG
      new_user(:email => 'Skip@example.org').valid?.should be_false
    end
    it 'ドメイン名に大文字を含むアドレスを許容すること' do
      new_user(:email => 'foo@Example.org').valid?.should be_true
    end
    it 'アカウント名とドメイン名に大文字を含むアドレスを許容すること' do
      new_user(:email => 'Foo@Example.org').valid?.should be_true
    end
  end
  describe 'pssword' do
    before do
      @user = create_user
      @user.stub!(:password_required?).and_return(true)
    end
    it '必須であること' do
      @user.password = ''
      @user.valid?.should be_false
      @user.errors['password'].include?('Password can\'t be blank').should be_true
    end
    it '確認用パスワードと一致すること' do
      @user.password = 'valid_password'
      @user.password_confirmation = 'invalid_password'
      @user.valid?.should be_false
      @user.errors['password'].include?('Password doesn\'t match confirmation').should be_true
    end
    it '6文字以上であること' do
      @user.password = 'abcd'
      @user.valid?.should be_false
      @user.errors['password'].include?('Password is too short (minimum is 6 characters)').should be_true
    end
    it '40文字以内であること' do
      @user.password = SkipFaker.rand_char(41)
      @user.valid?.should be_false
      @user.errors['password'].include?('Password is too long (maximum is 40 characters)').should be_true
    end
    it 'ログインIDと異なること' do
      @user.stub!(:uid).and_return('yamada')
      @user.password = 'yamada'
      @user.valid?.should be_false
      @user.errors['password'].should be_include('shall not be the same with login ID.')
    end
    it '現在のパスワードと異なること' do
      @user.password = 'Password2'
      @user.password_confirmation = 'Password2'
      @user.save!
      @user.password = 'Password2'
      @user.valid?.should be_false
      @user.errors['password'].should be_include('shall not be the same with the previous one.')
    end
    describe 'パスワード強度が弱の場合' do
      before do
        Admin::Setting.stub!(:password_strength).and_return('low')
      end
      it '6文字以上の英数字記号であること' do
        @user.password = 'abcde'
        @user.password_confirmation = 'abcde'
        @user.valid?
        [@user.errors['password']].flatten.size.should == 2
        @user.password = 'abcdef'
        @user.password_confirmation = 'abcdef'
        @user.valid?
        @user.errors['password'].should be_nil
      end
    end
    describe 'パスワード強度が中の場合' do
      before do
        Admin::Setting.stub!(:password_strength).and_return('middle')
      end
      it '7文字の場合エラー' do
        @user.password = 'abcdeF0'
        @user.valid?
        [@user.errors['password']].flatten.size.should == 1
      end
      describe '8文字以上の場合' do
        it '小文字のみの場合エラー' do
          @user.password = 'abcdefgh'
          @user.valid?
          [@user.errors['password']].flatten.size.should == 1
        end
        it '大文字のみの場合エラー' do
          @user.password = 'ABCDEFGH'
          @user.valid?
          [@user.errors['password']].flatten.size.should == 1
        end
        it '数字のみの場合エラー' do
          @user.password = '12345678'
          @user.valid?
          [@user.errors['password']].flatten.size.should == 1
        end
        it '記号のみの場合エラー' do
          @user.password = '####&&&&'
          @user.valid?
          [@user.errors['password']].flatten.size.should == 1
        end
        it '小文字、大文字のみの場合エラー' do
          @user.password = 'abcdEFGH'
          @user.valid?
          [@user.errors['password']].flatten.size.should == 1
        end
        it '小文字、大文字、数字の場合エラーにならないこと' do
          @user.password = 'abcdEF012'
          @user.password_confirmation = 'abcdEF012'
          @user.valid?
          @user.errors['password'].should be_nil
        end
      end
    end
    describe 'パスワード強度が強の場合' do
      before do
        Admin::Setting.stub!(:password_strength).and_return('high')
      end
      it '7文字の場合エラー' do
        @user.password = 'abcdeF0'
        @user.valid?
        [@user.errors['password']].flatten.size.should == 1
      end
      describe '8文字以上の場合' do
        it '小文字のみの場合エラー' do
          @user.password = 'abcdefgh'
          @user.valid?
          [@user.errors['password']].flatten.size.should == 1
        end
        it '大文字のみの場合エラー' do
          @user.password = 'ABCDEFGH'
          @user.valid?
          [@user.errors['password']].flatten.size.should == 1
        end
        it '数字のみの場合エラー' do
          @user.password = '12345678'
          @user.valid?
          [@user.errors['password']].flatten.size.should == 1
        end
        it '記号のみの場合エラー' do
          @user.password = '####&&&&'
          @user.valid?
          [@user.errors['password']].flatten.size.should == 1
        end
        it '小文字、大文字のみの場合エラー' do
          @user.password = 'abcdEFGH'
          @user.valid?
          [@user.errors['password']].flatten.size.should == 1
        end
        it '小文字、大文字、数字の場合エラー' do
          @user.password = 'abcdEF01'
          @user.valid?
          [@user.errors['password']].flatten.size.should == 1
        end
        it '小文字、大文字、数字, 記号の場合エラーとならないこと' do
          @user.password = 'abcdeF0@#'
          @user.password_confirmation = 'abcdeF0@#'
          @user.errors['password'].should be_nil
        end
      end
    end
  end
end

describe User, "#before_save" do
  before do
    SkipEmbedded::InitialSettings['login_mode'] = 'password'
    SkipEmbedded::InitialSettings['sha1_digest_key'] = "digest_key"
  end
  describe '新規の場合' do
    before do
      @user = new_user
      Admin::Setting.password_change_interval = 90
    end
    it 'パスワードが保存されること' do
      lambda do
        @user.save
      end.should change(@user, :crypted_password).from(nil)
    end
    it 'パスワード有効期限が設定されること' do
      time = Time.now
      Time.stub!(:now).and_return(time)
      lambda do
        @user.save
      end.should change(@user, :password_expires_at).to(Time.now.since(90.day))
    end
  end

  describe '更新の場合' do
    before do
      @user = new_user
      @user.save
      @user.reset_auth_token = 'reset_auth_token'
      @user.reset_auth_token_expires_at = Time.now
      @user.locked = true
      @user.trial_num = 1
      @user.save
      Admin::Setting.password_change_interval = 90
    end
    describe 'パスワードの変更の場合' do
      before do
        @user.password = 'Password99'
        @user.password_confirmation = 'Password99'
      end
      it 'パスワードが保存される' do
        lambda do
          @user.save
        end.should change(@user, :crypted_password).from(nil)
      end
      it 'パスワード有効期限が設定される' do
        time = Time.now
        Time.stub!(:now).and_return(time)
        lambda do
          @user.save
        end.should change(@user, :password_expires_at).to(Time.now.since(90.day))
      end
      it 'reset_auth_tokenがクリアされること' do
        lambda do
          @user.save
        end.should change(@user, :reset_auth_token).to(nil)
      end
      it 'reset_auth_token_expires_atがクリアされること' do
        lambda do
          @user.save
        end.should change(@user, :reset_auth_token_expires_at).to(nil)
      end
      it 'lockedがクリアされること' do
        lambda do
          @user.save
        end.should change(@user, :locked).to(false)
      end
      it 'trial_numがクリアされること' do
        lambda do
          @user.save
        end.should change(@user, :trial_num).to(0)
      end
    end

    describe 'パスワード以外の変更の場合' do
      before do
        @user.name = 'fuga'
      end
      it 'パスワードは変更されないこと' do
        lambda do
          @user.save
        end.should_not change(@user, :crypted_password)
      end
      it 'パスワード有効期限は設定されないこと' do
        lambda do
          @user.save
        end.should_not change(@user, :password_expires_at)
      end
      it 'reset_auth_tokenが変わらないこと' do
        lambda do
          @user.save
        end.should_not change(@user, :reset_auth_token)
      end
      it 'reset_auth_token_expires_atが変わらないこと' do
        lambda do
          @user.save
        end.should_not change(@user, :reset_auth_token_expires_at)
      end
      it 'lockedが変わらないこと' do
        lambda do
          @user.save
        end.should_not change(@user, :locked)
      end
      it 'trial_numが変わらないこと' do
        lambda do
          @user.save
        end.should_not change(@user, :trial_num)
      end
    end
  end

  describe 'ロックする場合' do
    before do
      @user = create_user(:user_options => {
        :auth_session_token => 'auth_session_token',
        :remember_token => 'remember_token',
        :remember_token_expires_at => Time.now
      })
      @user.locked = true
    end
    it 'セッション認証用のtokenが破棄されること' do
      lambda do
        @user.save
      end.should change(@user, :auth_session_token).to(nil)
    end
    it 'クッキー認証用のtokenが破棄されること' do
      lambda do
        @user.save
      end.should change(@user, :remember_token).to(nil)
    end
    it 'クッキー認証用のtokenの有効期限が破棄されること' do
      lambda do
        @user.save
      end.should change(@user, :remember_token_expires_at).to(nil)
    end
  end

  describe 'ロック状態が変化しない場合' do
    before do
      @user = create_user(:user_options => {
        :auth_session_token => 'auth_session_token',
        :remember_token => 'remember_token',
        :remember_token_expires_at => Time.now
      })
    end
    it 'セッション認証用のtokenが破棄されないこと' do
      lambda do
        @user.save
      end.should_not change(@user, :auth_session_token)
    end
    it 'クッキー認証用のtokenが破棄されないこと' do
      lambda do
        @user.save
      end.should_not change(@user, :remember_token)
    end
    it 'クッキー認証用のtokenの有効期限が破棄されないこと' do
      lambda do
        @user.save
      end.should_not change(@user, :remember_token_expires_at)
    end
  end
end

describe User, '#before_create' do
  before do
    @user = new_user
  end
  it '新規作成の際にはissued_atに現在日時が設定される' do
    time = Time.now
    Time.stub!(:now).and_return(time)
    lambda do
      @user.save
    end.should change(@user, :issued_at).to(nil)
  end
end

describe User, '#after_save' do
  describe '退職になったユーザの場合' do
    before do
      @user = create_user do |u|
        u.user_oauth_accesses.create(:app_name => 'wiki', :token => 'token', :secret => 'secret')
      end
    end
    it '対象ユーザのOAuthアクセストークンが削除されること' do
      lambda do
        @user.status = 'RETIRED'
        @user.save
      end.should change(@user.user_oauth_accesses, :size).by(-1)
    end
  end
  describe '利用中のユーザの場合' do
    before do
      @user = create_user do |u|
        u.user_oauth_accesses.create(:app_name => 'wiki', :token => 'token', :secret => 'secret')
      end
    end
    it '対象ユーザのOAuthアクセストークンが変化しないこと' do
      lambda do
        @user.name = 'new_name'
        @user.save
      end.should_not change(@user.user_oauth_accesses, :size)
    end
  end
end

describe User, '#change_password' do
  before do
    SkipEmbedded::InitialSettings['login_mode'] = 'password'
    SkipEmbedded::InitialSettings['sha1_digest_key'] = 'digest_key'
    @user = create_user(:user_options => {:password => 'Password1'})
    @old_password = 'Password1'
    @new_password = 'Hogehoge1'

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
  before do
    @identity_url = "http://test.com/identity"
    @params = { :code => 'hoge', :name => "ほげ ふが", :email => 'hoge@hoge.com' }
    @user = User.new_with_identity_url(@identity_url, @params)
    @user.stub!(:password_required?).and_return(false)
  end
  describe "正しく保存される場合" do
    it { @user.should be_valid }
    it { @user.should be_is_a(User) }
    it { @user.openid_identifiers.should_not be_nil }
    it { @user.openid_identifiers.map{|i| i.url}.should be_include(@identity_url) }
  end
  describe "バリデーションエラーの場合" do
    before do
      @user.name = ''
      @user.email = ''
    end
    it { @user.should_not be_valid }
    it "userにエラーが設定されていること" do
      @user.valid?
      @user.errors.full_messages.size.should == 3
    end
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
  subject { User.auth('code_or_email', "valid_password") { |result, user| @result = result; @authed_user = user } }

  describe "指定したログインID又はメールアドレスに対応するユーザが存在する場合" do
    before do
      @user = create_user
      @user.stub!(:crypted_password).and_return(User.encrypt("valid_password"))
      User.stub!(:find_by_code_or_email_with_key_phrase).and_return(@user)
    end
    describe "未使用ユーザの場合" do
      before do
        @user.stub!(:unused?).and_return(true)
      end
      it { should be_false }
    end
    describe "使用中ユーザの場合" do
      before do
        @user.stub!(:unused?).and_return(false)
        User.stub(:auth_successed).and_return(@user)
        User.stub(:auth_failed)
      end

      describe "パスワードが正しい場合" do
        it '認証成功処理が行われること' do
          User.should_receive(:auth_successed).with(@user)
          User.auth('code_or_email', "valid_password")
        end
        it "ユーザが返ること" do
          should be_true
          @authed_user.should == @user
        end
      end
      describe "パスワードは正しくない場合" do
        it '認証失敗処理が行われること' do
          User.should_receive(:auth_failed).with(@user)
          User.auth('code_or_email', 'invalid_password')
        end
        it "エラーメッセージが返ること" do
          User.auth('code_or_email', 'invalid_password').should be_false
        end
      end
      describe "パスワードの有効期限が切れている場合" do
        before do
          @user.stub!(:within_time_limit_of_password?).and_return(false)
        end
        it "エラーメッセージが返ること" do
          should be_false
          @authed_user.should == @user
        end
      end
      describe "アカウントがロックされている場合" do
        before do
          @user.stub!(:locked?).and_return(true)
        end
        it "エラーメッセージが返ること" do
          should be_false
          @authed_user.should == @user
        end
      end
    end
  end
  describe "指定したログインID又はメールアドレスに対応するユーザが存在しない場合" do
    before do
      User.should_receive(:find_by_code_or_email_with_key_phrase).at_least(:once).and_return(nil)
    end
    it { should be_false }
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
  describe 'シングルセッション機能が有効な場合' do
    before do
      Admin::Setting.should_receive(:enable_single_session).and_return(true)
    end
    it "トークンが保存されること" do
      @user.update_auth_session_token!
      @user.auth_session_token.should == @auth_session_token
    end
    it "トークンが返されること" do
      @user.update_auth_session_token!.should == @auth_session_token
    end
  end
  describe 'シングルセッション機能が無効な場合' do
    before do
      Admin::Setting.should_receive(:enable_single_session).and_return(false)
    end
    describe '新規ログインの場合(auth_session_tokenに値が入っていない)' do
      before do
        @user.auth_session_token = nil
      end
      it "トークンが保存されること" do
        @user.update_auth_session_token!
        @user.auth_session_token.should == @auth_session_token
      end
      it "トークンが返されること" do
        @user.update_auth_session_token!.should == @auth_session_token
      end
    end
    describe 'ログイン済みの場合(auth_session_tokenに値が入っている)' do
      before do
        @user.auth_session_token = 'auth_session_token'
      end
      it 'トークンが変化しないこと' do
        lambda do
          @user.update_auth_session_token!
        end.should_not change(@user, :auth_session_token)
      end
      it 'トークンが返されること' do
        @user.update_auth_session_token!.should == 'auth_session_token'
      end
    end
  end
end

describe User, '#issue_reset_auth_token' do
  before do
    @user = create_user
    @now = Time.local(2008, 11, 1)
    Time.stub!(:now).and_return(@now)
  end
  it 'reset_auth_tokenに値が入ること' do
    lambda do
      @user.issue_reset_auth_token
    end.should change(@user, :reset_auth_token)
  end
  it 'reset_auth_token_expires_atが24時間後となること' do
    lambda do
      @user.issue_reset_auth_token
    end.should change(@user, :reset_auth_token_expires_at).from(nil).to(@now.since(24.hour))
  end
end

describe User, '#determination_reset_auth_token' do
  before do
    @user = create_user
  end
  it 'reset_auth_tokenの値が更新されること' do
    prc = '6df711a1a42d110261cfe759838213143ca3c2ad'
    @user.reset_auth_token = prc
    lambda do
      @user.determination_reset_auth_token
    end.should change(@user, :reset_auth_token).from(prc).to(nil)
  end
  it 'reset_auth_token_expires_atの値が更新されること' do
    time = Time.now
    @user.reset_auth_token_expires_at = time
    lambda do
      @user.determination_reset_auth_token
    end.should change(@user, :reset_auth_token_expires_at).from(time).to(nil)
  end
end

describe User, '#issue_activation_code' do
  before do
    @user = create_user
    @now = Time.local(2008, 11, 1)
    User.stub!(:activation_lifetime).and_return(2)
    Time.stub!(:now).and_return(@now)
  end
  it 'activation_tokenに値が入ること' do
    lambda do
      @user.issue_activation_code
    end.should change(@user, :activation_token)
  end
  it 'activation_token_expires_atが48時間後となること' do
    lambda do
      @user.issue_activation_code
    end.should change(@user, :activation_token_expires_at).from(nil).to(@now.since(48.hour))
  end
end

describe User, '.issue_activation_codes' do
  before do
    @now = Time.local(2008, 11, 1)
    User.stub!(:activation_lifetime).and_return(2)
    Time.stub!(:now).and_return(@now)
  end
  describe '指定したIDのユーザが存在する場合' do
    before do
      @user = create_user(:status => 'UNUSED')
    end
    it '未使用ユーザのactivation_tokenに値が入ること' do
      unused_users, active_users = User.issue_activation_codes([@user.id])
      unused_users.first.activation_token.should_not be_nil
    end
    it '未使用ユーザのactivation_token_expires_atが48時間後となること' do
      unused_users, active_users = User.issue_activation_codes([@user.id])
      unused_users.first.activation_token_expires_at.should == @now.since(48.hour)
    end
  end
end

describe User, '#activate!' do
  it 'activation_tokenの値が更新されること' do
    activation_token = '6df711a1a42d110261cfe759838213143ca3c2ad'
    u = create_user(:user_options => {:activation_token=> activation_token}, :status => 'UNUSED')
    u.password = ''
    lambda do
      u.activate!
    end.should change(u, :activation_token).from(activation_token).to(nil)
  end
  it 'activation_token_expires_atの値が更新されること' do
    time = Time.now
    u = create_user(:user_options => {:activation_token_expires_at => time}, :status => 'UNUSED')
    u.password = ''
    lambda do
      u.activate!
    end.should change(u, :activation_token_expires_at).from(time).to(nil)
  end
end

describe User, '.activation_lifetime' do
  describe 'activation_lifetimeの設定が3(日)の場合' do
    before do
      Admin::Setting.stub!(:activation_lifetime).and_return(3)
    end
    it { User.activation_lifetime.should == 3 }
  end
end

describe User, '#within_time_limit_of_activation_token' do
  before do
    @activation_token_expires_at = Time.local(2008, 11, 1, 0, 0, 0)
    @activation_token = 'activation_token'
  end
  describe 'activation_token_expires_atが期限切れの場合' do
    before do
      @user = create_user(:user_options => {:activation_token => @activation_token, :activation_token_expires_at => @activation_token_expires_at })
      now = @activation_token_expires_at.since(1.second)
      Time.stub!(:now).and_return(now)
    end
    it 'falseが返ること' do
      @user.within_time_limit_of_activation_token?.should be_false
    end
  end
  describe 'activation_token_expires_atが期限切れではない場合' do
    before do
      @user = create_user(:user_options => {:activation_token => @activation_token, :activation_token_expires_at => @activation_token_expires_at })
      now = @activation_token_expires_at.ago(1.second)
      Time.stub!(:now).and_return(now)
    end
    it 'trueが返ること' do
      @user.within_time_limit_of_activation_token?.should be_true
    end
  end
end

describe User, '.grouped_sections' do
  before do
    User.delete_all
    create_user :user_options => {:email => SkipFaker.email, :section => 'Programmer'}, :user_uid_options => {:uid => SkipFaker.rand_num(6)}
    create_user :user_options => {:email => SkipFaker.email, :section => 'Programmer'}, :user_uid_options => {:uid => SkipFaker.rand_num(6)}
    create_user :user_options => {:email => SkipFaker.email, :section => 'Tester'}, :user_uid_options => {:uid => SkipFaker.rand_num(6)}
  end
  it {User.grouped_sections.size.should == 2}
end

describe User, "#find_or_initialize_profiles" do
  before do
    @user = new_user
    @user.save!
    @masters = (1..3).map{|i| create_user_profile_master(:name => "master#{i}")}
    @master_1_id = @masters[0].id
    @master_2_id = @masters[1].id
  end
  describe "設定されていないプロフィールがわたってきた場合" do
    it "新規に作成される" do
      @user.find_or_initialize_profiles(@master_1_id.to_s => "ほげ").should_not be_empty
    end
    it "新規の値が設定される" do
      @user.find_or_initialize_profiles(@master_1_id.to_s => "ほげ")
      @user.user_profile_values.each do |values|
        values.value.should == "ほげ" if values.user_profile_master_id == @master_1_id
      end
    end
    it "保存されていないprofile_valueが返される" do
      profiles = @user.find_or_initialize_profiles(@master_1_id.to_s => "ほげ")
      profiles.first.should be_is_a(UserProfileValue)
      profiles.first.value.should == "ほげ"
      profiles.first.should be_new_record
    end
  end
  describe "既に存在するプロフィールがわたってきた場合" do
    before do
      @user.user_profile_values.create(:user_profile_master_id => @master_1_id, :value => "ふが")
    end
    it "上書きされたものが返される" do
      profiles = @user.find_or_initialize_profiles(@master_1_id.to_s => "ほげ")
      profiles.first.should be_is_a(UserProfileValue)
      profiles.first.value.should == "ほげ"
      profiles.first.should be_changed
    end
  end
  describe "新規の値と保存された値が渡された場合" do
    before do
      @user.user_profile_values.create(:user_profile_master_id => @master_1_id, :value => "ふが")
      @profiles = @user.find_or_initialize_profiles(@master_1_id.to_s => "ほげ", @master_2_id.to_s => "ほげほげ")
    end
    it "保存されていたmaster_idが1のvalueは上書きされていること" do
      @profiles.each do |profile|
        if profile.user_profile_master_id == @master_1_id
          profile.value.should == "ほげ"
        end
      end
    end
    it "新規のmaster_idが2のvalueは新しく作られていること" do
      @profiles.each do |profile|
        if profile.user_profile_master_id == @master_2_id
          profile.value.should == "ほげほげ"
        end
      end
    end
  end
  describe "マスタに存在する値がパラメータで送られてこない場合" do
    before do
      @user.user_profile_values.create(:user_profile_master_id => @master_1_id, :value => "ほげ")
      @profiles = @user.find_or_initialize_profiles({})
      @profile_hash = @profiles.index_by(&:user_profile_master_id)
    end
    it "空が登録されること" do
      @profile_hash[@master_1_id].value.should == ""
    end
    it "マスタの数だけprofile_valuesが返ってくること" do
      @profiles.size.should == @masters.size
    end
  end
end

describe User, '#group_symbols' do
  before do
    @user = create_user
    @group = create_group(:gid => 'skip_dev') do |g|
      g.group_participations.build(:user_id => @user.id, :owned => true)
    end
    @group_symbols = ['gid:skip_dev']
  end
  describe '1度だけ呼ぶ場合' do
    it 'ユーザの所属するグループのシンボル配列を返すこと' do
      @user.group_symbols.should == @group_symbols
    end
  end
  describe '2度呼ぶ場合' do
    it 'ユーザの所属するグループのシンボル配列を返すこと(2回目はキャッシュされた結果になること)' do
      @user.group_symbols
      @user.group_symbols.should == @group_symbols
    end
  end
end

describe User, '#belong_symbols' do
  before do
    @user = stub_model(User, :symbol => 'uid:skipuser')
    @user.should_receive(:group_symbols).once.and_return(['gid:skip_dev'])
  end
  describe '1度だけ呼ぶ場合' do
    it 'ユーザ自身のシンボルとユーザの所属するグループのシンボルを配列で返すこと' do
      @user.belong_symbols.should == ['uid:skipuser', 'gid:skip_dev']
    end
  end
  describe '2度呼ぶ場合' do
    it 'ユーザ自身のシンボルとユーザの所属するグループのシンボルを配列で返すこと(2回目はキャッシュされた結果になること' do
      @user.belong_symbols
      @user.belong_symbols.should == ['uid:skipuser', 'gid:skip_dev']
    end
  end
end

describe User, "#belong_symbols_with_collaboration_apps" do
  before do
    SkipEmbedded::InitialSettings['host_and_port'] = 'test.host'
    SkipEmbedded::InitialSettings['protocol'] = 'http://'
    @user = stub_model(User, :belong_symbols => ["uid:a_user", "gid:a_group"], :code => "a_user")
  end
  describe "SkipEmbedded::InitialSettingsが設定されている場合" do
    before do
      SkipEmbedded::InitialSettings["belong_info_apps"] = {
        'app' => { "url" => "http://localhost:3100/notes.js", "ca_file" => "hoge/fuga" }
      }
    end
    describe "情報が返ってくる場合" do
      before do
        SkipEmbedded::WebServiceUtil.stub!(:open_service_with_url).and_return([{"publication_symbols" => "note:1"}, { "publication_symbols" => "note:4"}])
      end
      it "SKIP内の所属情報を返すこと" do
        ["uid:a_user", "gid:a_group", Symbol::SYSTEM_ALL_USER].each do |symbol|
          @user.belong_symbols_with_collaboration_apps.should be_include(symbol)
        end
      end
      it "SkipEmbedded::WebServiceUtilから他のアプリにアクセスすること" do
        SkipEmbedded::WebServiceUtil.should_receive(:open_service_with_url).with("http://localhost:3100/notes.js", { :user => "http://test.host/id/a_user" }, "hoge/fuga")
        @user.belong_symbols_with_collaboration_apps
      end
      it "連携アプリ内の所属情報を返すこと" do
        ["note:1"].each do |symbol|
          @user.belong_symbols_with_collaboration_apps.should be_include(symbol)
        end
      end
    end
    describe "情報が取得できない場合" do
      before do
        SkipEmbedded::WebServiceUtil.stub!(:open_service_with_url)
      end
      it "publicが追加されること" do
        ["uid:a_user", "gid:a_group", Symbol::SYSTEM_ALL_USER, "public"].each do |symbol|
          @user.belong_symbols_with_collaboration_apps.should be_include(symbol)
        end
      end
    end
  end
  describe "SkipEmbedded::InitialSettingsが設定されていない場合" do
    before do
      SkipEmbedded::InitialSettings["belong_info_apps"] = {}
    end
    it "SKIP内の所属情報を返すこと" do
      ["uid:a_user", "gid:a_group", Symbol::SYSTEM_ALL_USER, "public"].each do |symbol|
        @user.belong_symbols_with_collaboration_apps.should be_include(symbol)
      end
    end
  end
end

describe User, "#openid_identifier" do
  before do
    SkipEmbedded::InitialSettings['host_and_port'] = 'test.host'
    SkipEmbedded::InitialSettings['protocol'] = 'http://'
    @user = stub_model(User, :code => "a_user")
  end
  it "OPとして発行する OpenID identifier を返すこと" do
    @user.openid_identifier.should == "http://test.host/id/a_user"
  end
  it "relative_url_rootが設定されている場合 反映されること" do
    ActionController::Base.relative_url_root = "/skip"
    @user.openid_identifier.should == "http://test.host/skip/id/a_user"
  end
  after do
    ActionController::Base.relative_url_root = nil
  end
end

describe User, '#to_s_log' do
  before do
    @user = stub_model(User, :id => "99", :uid => '999999')
  end
  it 'ログに出力する形式に整えられた文字列を返すこと' do
    @user.to_s_log('message').should == "message: {\"user_id\" => \"#{@user.id}\", \"uid\" => \"#{@user.uid}\"}"
  end
end

describe User, '#locked?' do
  before do
    @user = stub_model(User)
  end
  describe 'ユーザロック機能が有効な場合' do
    before do
      Admin::Setting.enable_user_lock = 'true'
    end
    describe 'ユーザがロックされている場合' do
      before do
        @user.locked = true
      end
      it 'ロックされていると判定されること' do
        @user.locked?.should be_true
      end
    end
    describe 'ユーザがロックされていない場合' do
      before do
        @user.locked = false
      end
      it 'ロックされていないと判定されること' do
        @user.locked?.should be_false
      end
    end
  end
  describe 'ユーザロック機能が無効な場合' do
    before do
      Admin::Setting.enable_user_lock = 'false'
    end
    describe 'ユーザがロックされている場合' do
      before do
        @user.locked = true
      end
      it 'ロックされていると判定されること' do
        @user.locked?.should be_true
      end
    end
    describe 'ユーザがロックされていない場合' do
      before do
        @user.locked = false
      end
      it 'ロックされていないと判定されること' do
        @user.locked?.should be_false
      end
    end
  end
end

describe User, '#within_time_limit_of_password?' do
  before do
    @user = stub_model(User)
  end
  describe 'パスワード変更強制機能が有効な場合' do
    before do
      Admin::Setting.enable_password_periodic_change = 'true'
    end
    describe 'パスワードの有効期限切れ日が設定されている場合' do
      before do
        @user.password_expires_at = Time.local(2009, 3, 1, 0, 0, 0)
      end
      describe 'パスワード有効期限切れの場合' do
        before do
          now = Time.local(2009, 3, 1, 0, 0, 1)
          Time.stub!(:now).and_return(now)
        end
        it 'パスワード有効期限切れと判定されること' do
          @user.within_time_limit_of_password?.should be_false
        end
      end
      describe 'パスワード有効期限内の場合' do
        before do
          now = Time.local(2009, 3, 1, 0, 0, 0)
          Time.stub!(:now).and_return(now)
        end
        it 'パスワード有効期限内と判定されること' do
          @user.within_time_limit_of_password?.should be_true
        end
      end
    end
    describe 'パスワードの有効期限切れ日が設定されていない場合' do
      before do
        @user.password_expires_at = nil
      end
      it 'パスワード有効期限切れと判定されること' do
        @user.within_time_limit_of_password?.should be_nil
      end
    end

  end
  describe 'パスワード変更強制機能が無効な場合' do
    before do
      Admin::Setting.enable_password_periodic_change = 'false'
    end
    it 'パスワード有効期限内と判定されること' do
      @user.within_time_limit_of_password?.should be_true
    end
  end
end

describe User, '.synchronize_users' do
  describe '二人の利用中のユーザと一人の退職ユーザと一人の未使用ユーザが存在する場合' do
    before do
      User.delete_all
      SkipEmbedded::InitialSettings['host_and_port'] = 'localhost:3000'
      SkipEmbedded::InitialSettings['protocol'] = 'http://'
      @bob = create_user :user_options => {:name => 'ボブ', :admin => false}, :user_uid_options => {:uid => 'boob'}
      @alice = create_user :user_options => {:name => 'アリス', :admin => true}, :user_uid_options => {:uid => 'alice'}
      @carol = create_user :user_options => {:name => 'キャロル', :admin => false}, :user_uid_options => {:uid => 'carol'}, :status => 'RETIRED'
      @michael = create_user :user_options => { :name => "マイケル", :admin => false }, :user_uid_options => { :uid => 'michael' }, :status => "UNUSED"
      @users = User.synchronize_users
      @bob_attr, @alice_attr, @carol_attr, @michael_attr = @users
    end
    it '4件のユーザ同期情報を取得できること' do
      @users.size.should == 4
    end
    it 'ボブの情報が正しく設定されていること' do
      @bob_attr.should == ['http://localhost:3000/id/boob', 'boob', 'ボブ', false, false]
    end
    it 'アリスの情報が正しく設定されていること' do
      @alice_attr.should == ['http://localhost:3000/id/alice', 'alice', 'アリス', true, false]
    end
    it 'キャロルの情報が正しく設定されていること' do
      @carol_attr.should == ['http://localhost:3000/id/carol', 'carol', 'キャロル', false, true]
    end
    it "マイケルの情報が正しく設定されていること" do
      @michael_attr.should == ["http://localhost:3000/id/michael", 'michael', "マイケル", false, false]
    end

    describe 'ボブが4分59秒前に更新、アリスが5分前に更新、キャロル, マイケルが5分1秒前に更新されており、5分以内に更新があったユーザのみ取得する場合' do
      before do
        Time.stub!(:now).and_return(Time.local(2009, 6, 2, 0, 0, 0))
        User.record_timestamps = false
        @bob.update_attribute(:updated_on, Time.local(2009, 6, 1, 23, 54, 59))
        @alice.update_attribute(:updated_on, Time.local(2009, 6, 1, 23, 55, 0))
        @carol.update_attribute(:updated_on, Time.local(2009, 6, 1, 23, 55, 1))
        @michael.update_attribute(:updated_on, Time.local(2009, 6, 1, 23, 55, 1))
        @users = User.synchronize_users 5
        @alice_attr, @carol_attr, @michael_attr = @users
      end
      it '3件のユーザ同期情報を取得できること' do
        @users.size.should == 3
      end
      it 'アリスの情報が正しく設定されていること' do
        @alice_attr.should == ['http://localhost:3000/id/alice', 'alice', 'アリス', true, false]
      end
      it 'キャロルの情報が正しく設定されていること' do
        @carol_attr.should == ['http://localhost:3000/id/carol', 'carol', 'キャロル', false, true]
      end
      it "マイケルの情報が正しく設定されていること" do
        @michael_attr.should == ["http://localhost:3000/id/michael", 'michael', "マイケル", false, false]
      end
      after do
        User.record_timestamps = true
      end
    end
  end
end

describe User, "#custom" do
  it "関連するuser_customが存在するユーザの場合、そのuser_customが返る" do
    user = create_user
    custom = user.create_user_custom(:theme => "green", :editor_mode => "hiki")

    user.custom.should == custom
  end
  it "関連するuser_customが存在しないユーザの場合、新規のuser_customが取得返る" do
    user = create_user

    user.custom.should be_is_a(UserCustom)
    user.custom.should be_new_record
  end
end

describe User, '#participating_groups?' do
  before do
    @user = stub_model(User, :id => 99)
    @group = create_group
  end
  describe '指定したユーザがグループ参加者(参加済み)の場合' do
    before do
      group_participation = create_group_participation(:user_id => @user.id, :group_id => @group.id)
    end
    it 'trueが返ること' do
      @user.participating_group?(@group).should be_true
    end
  end
  describe '指定したユーザがグループ参加者(参加待ち)の場合' do
    before do
      group_participation = create_group_participation(:user_id => @user.id, :group_id => @group.id, :waiting => true)
    end
    it 'falseが返ること' do
      @user.participating_group?(@group).should be_false
    end
  end
  describe '指定したユーザがグループ管理者(参加済み)の場合' do
    before do
      group_participation = create_group_participation(:user_id => @user.id, :group_id => @group.id, :waiting => false, :owned => true)
    end
    it 'trueが返ること' do
      @user.participating_group?(@group).should be_true
    end
  end
  describe '指定したユーザがグループ管理者(参加待ち)の場合' do
    before do
      group_participation = create_group_participation(:user_id => @user.id, :group_id => @group.id, :waiting => true, :owned => true)
    end
    it 'falseが返ること' do
      @user.participating_group?(@group).should be_false
    end
  end
  describe '指定したユーザがグループ未参加者の場合' do
    before do
      group_participation = create_group_participation(:user_id => @user.id + 1, :group_id => @group.id)
    end
    it 'falseが返ること' do
      @user.participating_group?(@group).should be_false
    end
  end
  describe 'Group以外の場合' do
    it 'ArgumentErrorとなること' do
      lambda { @user.participating_group?(nil) }.should raise_error(ArgumentError)
    end
  end
end

describe User, 'password_required?' do
  before do
    @user = new_user
  end
  describe 'パスワードモードの場合' do
    before do
      SkipEmbedded::InitialSettings['login_mode'] = 'password'
    end
    describe 'パスワードが空の場合' do
      before do
        @user.password = ''
      end
      describe 'ユーザが利用中の場合' do
        before do
          @user.status = 'ACTIVE'
        end
        describe 'crypted_passwordが空の場合' do
          before do
            @user.crypted_password = ''
          end
          it '必要(true)と判定されること' do
            @user.send(:password_required?).should be_true
          end
        end
        describe 'crypted_passwordが空ではない場合' do
          before do
            @user.crypted_password = 'password'
          end
          it '必要ではない(false)と判定されること' do
            @user.send(:password_required?).should be_false
          end
        end
      end
      describe 'ユーザが利用中ではない場合' do
        before do
          @user.status = 'UNUSED'
        end
        it '必要ではない(false)と判定されること' do
          @user.send(:password_required?).should be_false
        end
      end
    end
    describe 'パスワードが空ではない場合' do
      before do
        @user.password = 'Password1'
      end
      it '必要(true)と判定されること' do
        @user.send(:password_required?).should be_true
      end
    end
  end
  describe 'パスワードモード以外の場合' do
    before do
      SkipEmbedded::InitialSettings['login_mode'] = 'rp'
    end
    it '必要ではない(false)と判定されること' do
      @user.send(:password_required?).should be_false
    end
  end
end

describe User, '.find_by_code_or_email_with_key_phrase' do
  before do
    @user = stub_model(User)
    User.stub!(:find_by_code_or_email).and_return(@user)
  end
  describe 'ログインキーフレーズが有効な場合' do
    before do
      Admin::Setting.should_receive(:enable_login_keyphrase).and_return(true)
      Admin::Setting.should_receive(:login_keyphrase).and_return('key_phrase')
    end
    describe 'ログインキーフレーズが設定値と一致する場合' do
      before do
        @key_phrase = 'key_phrase'
      end
      it 'ログインIDまたはemailで検索した結果が返ること' do
        User.send(:find_by_code_or_email_with_key_phrase, 'code_or_email', @key_phrase).should == @user
      end
    end
    describe 'ログインキーフレーズが設定値と一致しない場合' do
      before do
        @key_phrase = 'invalid_key_phrase'
      end
      it 'nilが返ること' do
        User.send(:find_by_code_or_email_with_key_phrase, 'code_or_email', @key_phrase).should be_nil
      end
    end
  end
  describe 'ログインキーフレーズが無効な場合' do
    before do
      Admin::Setting.should_receive(:enable_login_keyphrase).and_return(false)
    end
    it 'ログインIDまたはemailで検索した結果が返ること' do
      User.send(:find_by_code_or_email_with_key_phrase, 'code_or_email', @key_phrase).should == @user
    end
  end
end

describe User, '.find_by_code_or_email' do
  describe 'ログインIDに一致するユーザが見つかる場合' do
    before do
      @user = mock_model(User)
      User.should_receive(:find_by_code).and_return(@user)
    end
    it '見つかったユーザが返ること' do
      User.send(:find_by_code_or_email, 'login_id').should == @user
    end
  end
  describe 'ログインIDに一致するユーザが見つからない場合' do
    before do
      @user = mock_model(User)
      User.should_receive(:find_by_code).and_return(nil)
    end
    describe 'メールアドレスに一致するユーザが見つかる場合' do
      before do
        User.should_receive(:find_by_email).and_return(@user)
      end
      it '見つかったユーザが返ること' do
        User.send(:find_by_code_or_email, 'skip@example.org').should == @user
      end
    end
    describe 'メールアドレスに一致するユーザが見つからない場合' do
      before do
        User.should_receive(:find_by_email).and_return(nil)
      end
      it 'nilが返ること' do
        User.send(:find_by_code_or_email, 'skip@example.org').should be_nil
      end
    end
  end
end

describe User, '.auth_successed' do
  before do
    @user = create_user
  end
  it "検索されたユーザが返ること" do
    User.send(:auth_successed, @user).should == @user
  end
  describe 'ユーザがロックされている場合' do
    before do
      @user.should_receive(:locked?).and_return(true)
    end
    it 'last_authenticated_atが変化しないこと' do
      lambda do
        User.send(:auth_successed, @user)
      end.should_not change(@user, :last_authenticated_at)
    end
    it 'ログイン試行回数が変化しないこと' do
      lambda do
        User.send(:auth_successed, @user)
      end.should_not change(@user, :trial_num)
    end
  end
  describe 'ユーザがロックされていない場合' do
    before do
      @user.trial_num = 2
    end
    it "last_authenticated_atが現在時刻に設定されること" do
      time = Time.now
      Time.stub!(:now).and_return(time)
      lambda do
        User.send(:auth_successed, @user)
      end.should change(@user, :last_authenticated_at).to(time)
    end
    it 'ログイン試行回数が0になること' do
      lambda do
        User.send(:auth_successed, @user)
      end.should change(@user, :trial_num).to(0)
    end
  end
end

describe User, '.auth_failed' do
  before do
    @user = create_user
  end
  it 'nilが返ること' do
    User.send(:auth_failed, @user).should be_nil
  end
  describe 'ユーザがロックされていない場合' do
    before do
      @user.should_receive(:locked?).and_return(false)
    end
    describe 'ログイン試行回数が最大値未満の場合' do
      before do
        @user.trial_num = 2
        Admin::Setting.user_lock_trial_limit = 3
      end
      describe 'ユーザロック機能が有効な場合' do
        before do
          Admin::Setting.enable_user_lock = 'true'
        end
        it 'ログイン試行回数が1増加すること' do
          lambda do
            User.send(:auth_failed, @user)
          end.should change(@user, :trial_num).to(3)
        end
      end
      describe 'ユーザロック機能が無効な場合' do
        before do
          Admin::Setting.enable_user_lock = 'false'
        end
        it 'ログイン試行回数が変化しないこと' do
          lambda do
            User.send(:auth_failed, @user)
          end.should_not change(@user, :trial_num)
        end
      end
    end
    describe 'ログイン試行回数が最大値以上の場合' do
      before do
        @user.trial_num = 3
        Admin::Setting.user_lock_trial_limit = 3
      end
      describe 'ユーザロック機能が有効な場合' do
        before do
          Admin::Setting.enable_user_lock = 'true'
        end
        it 'ロックされること' do
          lambda do
            User.send(:auth_failed, @user)
          end.should change(@user, :locked).to(true)
        end
        it 'ロックした旨のログが出力されること' do
          @user.should_receive(:to_s_log).with('[User Locked]').and_return('user locked log')
          @user.logger.should_receive(:info).with('user locked log')
          User.send(:auth_failed, @user)
        end
      end
      describe 'ユーザロック機能が無効な場合' do
        before do
          Admin::Setting.enable_user_lock = 'false'
        end
        it 'ロック状態が変化しないこと' do
          lambda do
            User.send(:auth_failed, @user)
          end.should_not change(@user, :locked)
        end
        it 'ロックした旨のログが出力されないこと' do
          @user.stub!(:to_s_log).with('[User Locked]').and_return('user locked log')
          @user.logger.should_not_receive(:info).with('user locked log')
          User.send(:auth_failed, @user)
        end
      end
    end
  end
  describe 'ユーザがロックされている場合' do
    before do
      @user.should_receive(:locked?).and_return(true)
    end
    it 'ログイン試行回数が変化しないこと' do
      lambda do
        User.send(:auth_failed, @user)
      end.should_not change(@user, :trial_num)
    end
    it 'ロック状態が変化しないこと' do
      lambda do
        User.send(:auth_failed, @user)
      end.should_not change(@user, :locked)
    end
    it 'ロックした旨のログが出力されないこと' do
      @user.stub!(:to_s_log).with('[User Locked]').and_return('user locked log')
      @user.logger.should_not_receive(:info).with('user locked log')
      User.send(:auth_failed, @user)
    end
  end
end

def new_user options = {}
  User.new({ :name => 'ほげ ほげ', :password => 'Password1', :password_confirmation => 'Password1', :email => SkipFaker.email, :section => 'Tester',}.merge(options))
end

