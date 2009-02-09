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
  before do
    @valid_password = 'valid_password'
  end
  describe "指定したログインID又はメールアドレスに対応するユーザが存在する場合" do
    before do
      @user = mock_model(User)
      @user.stub!(:crypted_password).and_return(User.encrypt(@valid_password))
      User.stub!(:find_by_code_or_email).and_return(@user)
    end
    describe "未使用ユーザの場合" do
      before do
        @user.stub!(:unused?).and_return(true)
        User.should_receive(:find_by_code_or_email).and_return(@user)
      end
      it { User.auth('code_or_email', @valid_password).should be_nil }
    end
    describe "使用中ユーザの場合" do
      before do
        @user.stub!(:unused?).and_return(false)
        @user.stub!(:last_authenticated_at=)
        @user.stub!(:save).with(false)
        User.should_receive(:find_by_code_or_email).and_return(@user)
      end
      describe "パスワードが正しい場合" do
        it "検索されたユーザが返ること" do
          User.auth('code_or_email', @valid_password).should == @user
        end
        it "last_authenticated_atが現在時刻に設定されること" do
          time = Time.now
          Time.stub!(:now).and_return(time)
          @user.should_receive(:last_authenticated_at=).with(time)
          @user.should_receive(:save).with(false)
          User.auth("code_or_email", @valid_password)
        end
      end
      describe "パスワードは正しくない場合" do
        it { User.auth('code_or_email', 'invalid_password').should be_nil }
      end
    end
  end
  describe "指定したログインID又はメールアドレスに対応するユーザが存在しない場合" do
    before do
      User.should_receive(:find_by_code_or_email).and_return(nil)
    end
    it { User.auth('code_or_email', @valid_password).should be_nil }
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
  it 'reset_auth_tokenの値が更新されること' do
    prc = '6df711a1a42d110261cfe759838213143ca3c2ad'
    u = create_user(:user_options => {:reset_auth_token => prc})
    lambda do
      u.determination_reset_auth_token
    end.should change(u, :reset_auth_token).from(prc).to(nil)
  end
  it 'reset_auth_token_expires_atの値が更新されること' do
    time = Time.now
    u = create_user(:user_options => {:reset_auth_token_expires_at => time})
    lambda do
      u.determination_reset_auth_token
    end.should change(u, :reset_auth_token_expires_at).from(time).to(nil)
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

describe User, '#activate!' do
  it 'activation_tokenの値が更新されること' do
    activation_token = '6df711a1a42d110261cfe759838213143ca3c2ad'
    u = create_user(:user_options => {:activation_token=> activation_token})
    lambda do
      u.activate!
    end.should change(u, :activation_token).from(activation_token).to(nil)
  end
  it 'activation_token_expires_atの値が更新されること' do
    time = Time.now
    u = create_user(:user_options => {:activation_token_expires_at => time})
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

describe User, "#section" do
  before do
    @user = User.new
    @attr = { :email => SkipFaker.email, :name => "名字 名前" }
  end
  describe "sectionがわたってきた場合" do
    describe "全角のsectionの場合" do
      it "半角に統一されて登録されること" do
        @user.attributes = @attr.merge!(:section => "INＰUＴ_部署")
        @user.save!
        @user.section.should == "INPUT_部署"
      end
    end
  end
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
    @user = stub_model(User)
    @group_symbols = ['gid:skip_dev']
    GroupParticipation.should_receive(:get_gid_array_by_user_id).with(@user.id).once.and_return(@group_symbols)
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
    Admin::Setting.stub!(:host_and_port_by_initial_settings_default).and_return("test.host")
    Admin::Setting.stub!(:protocol_by_initial_settings_default).and_return("http://")
    @user = stub_model(User, :belong_symbols => ["uid:a_user", "gid:a_group"], :code => "a_user")
  end
  describe "INITIAL_SETTINGSが設定されている場合" do
    before do
      INITIAL_SETTINGS["belong_info_apps"] = { 'app' => { "url" => "http://localhost:3100/notes.js", "ca_file" => "hoge/fuga" } }
    end
    describe "情報が返ってくる場合" do
      before do
        WebServiceUtil.stub!(:open_service_with_url).and_return([{"publication_symbols" => "note:1"}, { "publication_symbols" => "note:4"}])
      end
      it "SKIP内の所属情報を返すこと" do
        ["uid:a_user", "gid:a_group", Symbol::SYSTEM_ALL_USER].each do |symbol|
          @user.belong_symbols_with_collaboration_apps.should be_include(symbol)
        end
      end
      it "WebServiceUtilから他のアプリにアクセスすること" do
        WebServiceUtil.should_receive(:open_service_with_url).with("http://localhost:3100/notes.js", { :user => "http://test.host/id/a_user" }, "hoge/fuga")
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
        WebServiceUtil.stub!(:open_service_with_url)
      end
      it "何も追加されないこと" do
        @user.belong_symbols_with_collaboration_apps.size.should == 3
      end
    end
  end
  describe "INITIAL_SETTINGSが設定されていない場合" do
    before do
      INITIAL_SETTINGS["belong_info_apps"] = nil
    end
    it "SKIP内の所属情報を返すこと" do
      ["uid:a_user", "gid:a_group", Symbol::SYSTEM_ALL_USER].each do |symbol|
        @user.belong_symbols_with_collaboration_apps.should be_include(symbol)
      end
    end
  end
end

describe User, "#openid_identifier" do
  before do
    Admin::Setting.stub!(:host_and_port_by_initial_settings_default).and_return("test.host")
    Admin::Setting.stub!(:protocol_by_initial_settings_default).and_return("http://")
    @user = stub_model(User, :code => "a_user")
  end
  it "OPとして発行する OpenID identifier を返すこと" do
    @user.openid_identifier.should == "http://test.host/id/a_user"
  end
  it "relative_url_rootが設定されている場合 反映されること" do
    ActionController::AbstractRequest.relative_url_root = "/skip"
    @user.openid_identifier.should == "http://test.host/skip/id/a_user"
  end
  after do
    ActionController::AbstractRequest.relative_url_root = nil
  end
end

describe User, '.find_by_code_or_email' do
  describe 'ログインIDに一致するユーザが見つかる場合' do
    before do
      @user = mock_model(User)
      User.should_receive(:find_by_code).and_return(@user)
    end
    it '見つかったユーザが返ること' do
      User.find_by_code_or_email('login_id').should == @user
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
        User.find_by_code_or_email('skip@example.org').should == @user
      end
    end
    describe 'メールアドレスに一致するユーザが見つからない場合' do
      before do
        User.should_receive(:find_by_email).and_return(nil)
      end
      it 'nilが返ること' do
        User.find_by_code_or_email('skip@example.org').should be_nil
      end
    end
  end
end

def new_user options = {}
  User.new({ :name => 'ほげ ほげ', :password => 'password', :password_confirmation => 'password', :email => SkipFaker.email, :section => 'Tester',}.merge(options))
end

