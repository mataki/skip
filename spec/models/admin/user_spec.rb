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

describe Admin::User, '.make_users' do
  before do
    @user = mock_model(Admin::User)
    @user_uid = mock_model(Admin::UserUid)
    FasterCSV.should_receive(:parse).and_return([['hoge']])
    Admin::User.stub!(:make_user_hash_from_csv_line).and_return({},{},{})
    Admin::User.should_receive(:make_user).and_return([@user, @user_uid])
  end
  it { Admin::User.send(:make_users, mock('uplocaded_file'), mock('options')).should == ([[@user, @user_uid]]) }
end

describe Admin::User, '.make_user' do
  describe '既存のレコードがある場合' do
    describe "既存のユーザを更新する場合" do
      before do
        user_uid_hash = {:uid => SkipFaker.rand_num(6)}
        user = create_user :user_options => {:section => 'プログラマ', :email => SkipFaker.email}, :user_uid_options => user_uid_hash
        @user_hash = user.attributes
        @user_uid_hash = user.user_uids.find_by_uid_type('MASTER')
      end
      it 'make_user_by_uidが呼ばれること' do
        Admin::User.should_receive(:make_user_by_uid)
        @user, @user_uid = Admin::User.make_user({:user => @user_hash, :user_uid => @user_uid_hash}, false, false)
      end
    end
    describe "既存のレコードを更新しない場合" do
      before do
        user_hash = {:section => 'プログラマ', :email => SkipFaker.email}
        user_uid_hash = {:uid => SkipFaker.rand_num(6)}
        user = create_user :user_options => user_hash, :user_uid_options => user_uid_hash
        @user_hash = user.attributes
        @user_uid_hash = user.user_uids.find_by_uid_type('MASTER')
      end
      it 'make_user_by_uidが属性なしで呼ばれること' do
        Admin::User.should_receive(:make_user_by_uid).with({:user => {}, :user_uid => {:uid => @user_uid_hash[:uid]}}, false)
        @use, @user_uid = Admin::User.make_user({:user => @user_hash, :user_uid => @user_uid_hash}, false, true)
      end
    end
  end
  describe '既存のレコードがない場合' do
    it 'make_new_userが呼ばれること' do
      Admin::User.should_receive(:make_new_user)
      @user, @user_uid = Admin::User.make_user({:user => {}, :user_uid => {:uid => 'skipuser'}})
    end
  end
end

describe Admin::User, '.make_new_user' do
  before do
    @uid = '999999'
    @email = "yamada@example.com"
    @password = "password"
    @fullname = "山田 太郎"
    @job_title = "経理"
    @user_hash = {:name => @fullname, :password => @password, :password_confirmation => @password, :section => @job_title, :email => @email}
    @user_uid_hash = {:uid => @uid}
  end
  describe '管理者を作成する場合' do
    before do
      @user, @user_uid = Admin::User.make_new_user({:user => @user_hash, :user_uid => @user_uid_hash}, true)
    end
    it '新規レコードであること' do
      @user.new_record?.should be_true
    end
    it 'fullnameが設定されていること' do
      @user.name.should == @fullname
    end
    it 'passwordが設定されていること' do
      @user.password.should == @password
    end
    it 'password_confirmationが設定されていること' do
      @user.password_confirmation == @password_confirmation
    end
    it '管理者であること' do
      @user.admin.should be_true
    end
    it 'statusが有効化されていること' do
      @user.status.should == :ACTIVE.to_s
    end
    it 'sectionが設定されていること' do
      @user.section.should == @job_title
    end
    it 'emailが設定されていること' do
      @user.email.should == @email
    end
    it { @user.user_uids.include?(@user_uid).should be_true }
    it 'uidが設定されていること' do
      @user_uid.uid.should == @uid
    end
  end
  describe '一般ユーザを作成する場合' do
    before do
      @user, @user_uid = Admin::User.make_user({:user => @user_hash, :user_uid => @user_uid_hash})
    end
    it '管理者でないこと' do
      @user.admin.should be_false
    end
    it 'statusが無効化されていること' do
      @user.status.should == :UNUSED.to_s
    end
  end
end

describe Admin::User, '.make_user_by_uid' do
    before do
      @uid = '999999'
      @email = "yamada@example.com"
      @password = "Password1"
      @fullname = "山田 太郎"
      @job_title = "経理"
      @user_hash = {:name => @fullname, :password => @password, :password_confirmation => @password, :section => @job_title, :email => @email}
      @user_uid_hash = {:uid => SkipFaker.rand_num(6)}
      user = create_user :user_options => @user_hash, :user_uid_options => @user_uid_hash
      @user, @user_uid = Admin::User.make_user_by_uid({:user => @user_hash, :user_uid => @user_uid_hash})
    end
    it '新規レコードではないこと' do
      @user.new_record?.should_not be_true
    end
    it 'fullnameが設定されていること' do
      @user.name.should == @fullname
    end
    it 'passwordが設定されていること' do
      @user.password.should == @password
    end
    it 'password_confirmationが設定されていること' do
      @user.password_confirmation == @password_confirmation
    end
    it 'sectionが設定されていること' do
      @user.section.should == @job_title
    end
    it 'emailが設定されていること' do
      @user.email.should == @email
    end
end

describe Admin::User, '.make_user_by_id' do
  before do
    @password = "password"
    @fullname = "山田 太郎"
    @job_title = "経理"
    @admin = "1"
    @status = "RETIRED"

    @user_hash = {:name => @fullname, :password => @password, :password_confirmation => @password, :admin => @admin, :status => @status}
    user = create_user
    @user = Admin::User.make_user_by_id({:id => user.id, :user => @user_hash})
  end

  it '新規レコードではないこと' do
    @user.new_record?.should_not be_true
  end
  it 'fullnameが設定されていること' do
    @user.name.should == @fullname
  end
  it 'passwordが設定されていること' do
    @user.password.should == @password
  end
  it 'password_confirmationが設定されていること' do
    @user.password_confirmation == @password_confirmation
  end
  it 'adminが設定されていること' do
    @user.admin.should be_true
  end
  it 'statusが設定されていること' do
    @user.status.should == @status
  end
end

describe Admin::User, ".make_user_hash_from_csv_line" do
  before do
    @line = %w(111111 山田太郎 yamada@example.com)
    @options = {:name => "1", :email => "1"}
  end
  describe "部署もアップデートする場合" do
    before do
      @line.push('経理')
      @options.merge!(:section => "1")
    end
    it "部署を含んだ配列を返す" do
      Admin::User.send(:make_user_hash_from_csv_line, @line, @options).should == [{:name=>"山田太郎", :section=>"経理", :email=>"yamada@example.com"}, {:uid=>"111111"}]
    end
  end
  describe "部署をアップデートしない場合" do
    it "部署を含まない配列を返す" do
      Admin::User.send(:make_user_hash_from_csv_line, @line, @options).should == [{:name=>"山田太郎", :email=>"yamada@example.com"}, {:uid=>"111111"}]
    end
  end
  describe "optionsがnilの場合" do
    it "uidのみ入った配列を返す" do
      Admin::User.send(:make_user_hash_from_csv_line, @line, nil).should == [{}, {:uid=>"111111"}]
    end
  end
  describe "emailのみアップデートしない場合" do
    before do
      @line = %w(111111 山田太郎 経理)
      @options = {:name => "1", :section => "1"}
    end
    it "emailのみが設定されていないこと" do
      Admin::User.send(:make_user_hash_from_csv_line, @line, @options).should == [{:name=>"山田太郎", :section => "経理"}, {:uid=>"111111"}]
    end
  end
end

describe Admin::User, '.lock_actives' do
  before do
    user_options = {
      :auth_session_token => 'auth_session_token',
      :remember_token => 'remember_token',
      :remember_token_expires_at => Time.now
    }
    @active_user = create_user(:user_options  => user_options)
    @admin_user = create_user(:user_options => user_options.merge!(:admin => true))
    @unused_user = create_user(:user_options => user_options, :status => 'UNUSED')
  end
  describe '利用中ユーザ全てをロックできる場合' do
    before do
      Admin::User.should_receive(:enable_forgot_password?).and_return(true)
    end
    it '一般の利用中ユーザがロックされること' do
      lambda do
        Admin::User.lock_actives
        @active_user.reload
      end.should change(@active_user, :locked).to(true)
    end
    it '一般の利用中ユーザの認証情報がクリアされること' do
      Admin::User.lock_actives
      @active_user.reload
      @active_user.auth_session_token.should be_nil
      @active_user.remember_token.should be_nil
      @active_user.remember_token_expires_at.should be_nil
    end
    it '管理者ユーザがロックされること' do
      lambda do
        Admin::User.lock_actives
        @admin_user.reload
      end.should change(@admin_user, :locked).to(true)
    end
    it '管理者ユーザの認証情報がクリアされること' do
      Admin::User.lock_actives
      @admin_user.reload
      @admin_user.auth_session_token.should be_nil
      @admin_user.remember_token.should be_nil
      @admin_user.remember_token_expires_at.should be_nil
    end
    it '未使用ユーザがロックされないこと' do
      lambda do
        Admin::User.lock_actives
        @unused_user = Admin::User.find_by_id(@unused_user.id)
      end.should_not change(@unused_user, :locked)
    end
  end
  describe '利用中ユーザ全てをロックできない場合' do
    before do
      Admin::User.should_receive(:enable_forgot_password?).and_return(false)
    end
    it '一般の利用中ユーザの情報(ロック、認証)に変化がないこと' do
      lambda do
        Admin::User.lock_actives
        @active_user.reload
      end.should_not change(@unused_user, :to_s)
    end
    it '管理者ユーザの情報(ロック、認証)に変化がないこと' do
      lambda do
        Admin::User.lock_actives
        @admin_user.reload
      end.should_not change(@unused_user, :to_s)
    end
    it '未使用ユーザの情報(ロック、認証)に変化がないこと' do
      lambda do
        Admin::User.lock_actives
        @unused_user = Admin::User.find_by_id(@unused_user.id)
      end.should_not change(@unused_user, :to_s)
    end
    it '0が返ること' do
      Admin::User.lock_actives.should == 0
    end
  end
end
