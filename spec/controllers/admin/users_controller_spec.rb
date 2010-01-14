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

describe Admin::UsersController, 'GET /new' do
  before do
    admin_login
    get :new
  end
  it {assigns[:user].should_not be_nil}
  it {assigns[:user_uid].should_not be_nil}
  it {assigns[:topics].should_not be_nil}
  it {response.should be_success}
end

describe Admin::UsersController, 'POST /create' do
  before do
    admin_login
    @user = stub_model(Admin::User)
    @user.stub!(:save!)
    @user_uid = stub_model(Admin::UserUid)
    Admin::User.stub!(:make_new_user).and_return([@user, @user_uid])
    SkipEmbedded::InitialSettings['login_mode'] = 'password'
  end
  describe 'ユーザの登録に成功する場合' do
    it 'Admin::Userが作成されること' do
      @user.should_receive(:save!)
      Admin::User.should_receive(:make_new_user).and_return([@user, @user_uid])
      post :create
    end
    it {post :create; flash[:notice].should_not be_nil}
    it {post :create; response.should be_redirect}
  end
  describe 'ユーザの登録に失敗する場合' do
    before do
      @user.should_receive(:save!).and_raise(mock_record_invalid)
      post :create
    end
    it {response.should be_success}
    it {response.should render_template('new')}
  end
end

describe Admin::UsersController, 'GET /edit' do
  before do
    admin_login
    @user = stub_model(Admin::User)
    Admin::User.stub!(:find).and_return(@user)
    @user_uid = stub_model(Admin::UserUid)
    @user.stub!(:master_user_uid).and_return(@user_uid)
    get :edit
  end
  it {assigns[:user].should_not be_nil}
  it {assigns[:user_uid].should_not be_nil}
  it {assigns[:topics].should_not be_nil}
  it {response.should be_success}
end

describe Admin::UsersController, 'POST #update' do
  before do
    admin_login

    @user = stub_model(Admin::User)
    Admin::User.stub!(:make_user_by_id).and_return(@user)
  end
  describe "正しく更新できた場合" do
    before do
      @user.should_receive(:save!)

      post :update
    end
    it "flashに更新しましたのメッセージが入っていること" do
      flash[:notice].should == 'Updated.'
    end
    it { response.should be_redirect }
  end
  describe "更新できなかった場合" do
    before do
      @user.should_receive(:save!).and_raise(mock_record_invalid)

      post :update
    end
    it { response.should render_template('admin/users/edit') }
    it "@userが設定されていること" do
      assigns[:user].should == @user
    end
  end
  describe "自分自身を更新する場合" do
    before do
      @before_status = mock('before_status')
      @before_admin = mock('before admin')
      @before_lock = mock('before_lock')
      @admin_user = admin_login
      @admin_user.stub!(:status).and_return(@before_status)
      @admin_user.stub!(:admin).and_return(@before_admin)
      @admin_user.stub!(:locked).and_return(@before_lock)
      @admin_user.stub!(:id).and_return(@user.id)

      @user.stub!(:save!)
    end
    it "ステータスが変更されない" do
      @user.should_receive(:status=).with(@before_status)
      post :update
    end
    it "管理権限が変更されない" do
      @user.should_receive(:admin=).with(@before_admin)
      post :update
    end
    it 'ロック状態が変更されない' do
      @user.should_receive(:locked=).with(@before_lock)
      post :update
    end
    it "編集画面がrenderされる" do
      post :update
      response.should render_template('admin/users/edit')
    end
  end
  describe '他者を更新する場合' do
    describe 'ロックされていない場合' do
      before do
        @user.locked = false
      end
      it '試行回数に0が設定されること' do
        @user.should_receive(:trial_num=).with(0)
        post :update
      end
    end
    describe 'ロックされている場合' do
      before do
        @user.locked = true
      end
      it '試行回数が設定されないこと' do
        @user.should_not_receive(:trial_num=)
        post :update
      end
    end
  end
end

describe Admin::UsersController, 'POST #destroy' do
  before do
    admin_login

    @user = mock_model(Admin::User)
    Admin::User.stub!(:find).with('1').and_return(@user)
  end
  describe "未登録ユーザの場合" do
    before do
      @user.should_receive(:unused?).and_return(true)
      @user.should_receive(:destroy)

      post :destroy, :id => 1
    end
    it { redirect_to admin_users_path }
    it { flash[:notice].should == 'User was successfuly deleted.' }
  end
  describe "未登録ユーザでない場合" do
    before do
      @user.should_receive(:unused?).and_return(false)
      @user.should_not_receive(:destroy)

      post :destroy, :id => 1
    end
    it { redirect_to admin_users_path }
    it { flash[:notice].should == "You cannot delete user who is not unused." }
  end
end

describe Admin::UsersController, 'GET /first' do
  describe '有効なactivation_codeの場合' do
    before do
      controller.should_receive(:valid_activation_code?).and_return(true)
      get :first
    end
    it {response.should be_success}
    it {assigns[:user].should_not be_nil}
    it {assigns[:user_uid].should_not be_nil}
  end
end

describe Admin::UsersController, 'POST /first' do
  describe '有効なactivation_codeの場合' do
    before do
      controller.stub!(:valid_activation_code?).and_return(true)
      @user = stub_model(Admin::User)
      @user_uid = stub_model(Admin::UserUid)
      @activation = stub_model(Activation)
      @user.stub!(:user_access=)
      Admin::User.stub!(:make_user).and_return([@user, @user_uid])
    end
    describe '管理者ユーザの登録に成功する場合' do
      # ユーザが作成されること
      before do
        @user.should_receive(:user_access=)
        @user.should_receive(:save!)
        Admin::User.should_receive(:make_user).and_return([@user, @user_uid])
        @activation.should_receive(:update_attributes).with({:code => nil})
        Activation.should_receive(:find_by_code).and_return(@activation)
        post :first, {:user => {"name"=>"管理者", "password_confirmation"=>"[FILTERED]", "password"=>"[FILTERED]", "email"=>"admin@skip.org", "section"=>"管理部"}, :user_uid => {:uid => 'admin'}}
      end
      it {flash[:notice].should_not be_nil}
      it {response.should be_redirect}
    end
    describe '管理者ユーザの登録に失敗する場合' do
      before do
        @user.should_receive(:save!).and_raise(mock_record_invalid)
        post :first, :user_uid => {}
      end
      it {response.should be_success}
      it {response.should render_template('first')}
    end
  end
  describe '無効なactivation_codeの場合' do
    before do
      controller.should_receive(:valid_activation_code?).and_return(false)
    end
    describe "管理者ユーザが登録されていない場合" do
      before do
        User.should_receive(:find_by_admin).and_return(nil)
        post :first
      end
      it "forbiddenのレスポンスが返ること" do
        response.code.should == '403'
      end
    end
    describe "管理者ユーザが登録されている場合" do
      before do
        User.should_receive(:find_by_admin).and_return(stub_model(User))
        post :first
      end
      it "リダイレクトされること" do
        response.should be_redirect
      end
    end
  end
end

describe Admin::UsersController, '#valid_activation_code?' do
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

describe Admin::UsersController, 'GET /import' do
  before do
    admin_login
    get :import
  end
  it { response.should render_template('import') }
  it { assigns[:users].should_not be_nil }
end

describe Admin::UsersController, 'POST /import' do
  before do
    admin_login
  end
  describe '不正なファイルの場合' do
    before do
      controller.should_receive(:valid_file?).and_return(false)
      post :import
    end
    it { response.should render_template('import') }
    it { assigns[:users].should_not be_nil }
  end
  describe '正常なファイルの場合' do
    before do
      @new_user = stub_model(Admin::User)
      @new_user_uid = stub_model(Admin::UserUid)
      @edit_user = stub_model(Admin::User)
      @edit_user_uid = stub_model(Admin::UserUid)
      controller.stub!(:import!)
      @edit_user_uid.stub!(:save!)
      controller.should_receive(:valid_file?).and_return(true)
    end
    describe '1件が新規、1件が既存レコードの場合' do
      before do
        @new_user.stub!(:new_record?).and_return(true)
        @edit_user.stub!(:new_record?).and_return(false)
        Admin::User.should_receive(:make_users).and_return([[@new_user, @new_user_uid], [@edit_user, @edit_user_uid]])
      end
      it '新規レコードはUserのみ、既存レコードはUser, UserUidの各々で保存されること' do
        controller.should_receive(:import!)
        post :import
      end

      it { post :import; flash[:notice].should_not be_nil }
      it { post :import; response.should redirect_to(admin_users_path) }
    end
    describe 'invalidなレコードが含まれる場合' do
      before do
        controller.should_receive(:import!).and_raise(mock_record_invalid)
        Admin::User.should_receive(:make_users).and_return([@new_user, @new_user_uid])
        post :import
      end
      it { response.should render_template('import') }
    end
  end
end

describe Admin::UsersController, "POST #change_uid" do
  before do
    admin_login

    @user_uid = stub_model(Admin::UserUid)

    @user_uids = mock('user_uids')
    @user_uids.stub!(:find).and_return(@user_uid)

    @user = stub_model(Admin::User)
    @user.status = 'ACTIVE'
    @user.stub!(:user_uids).and_return(@user_uids)

    Admin::User.should_receive(:find).and_return(@user)
  end
  describe "保存に成功する時" do
    before do
      @user_uid.should_receive(:save).and_return(true)

      post_change_uid
    end
    it { response.should be_redirect }
    it { flash[:notice].should_not be_nil }
  end
  describe "保存に失敗する時" do
    before do
      @user_uid.should_receive(:save).and_return(false)

      post_change_uid
    end
    it { response.should render_template('admin/users/change_uid') }
    it { assigns[:user].should == @user }
  end
  describe "ユーザ名が見つからない時" do
    before do
      @user_uids.should_receive(:find).and_return(nil)

      post_change_uid
    end
    it { response.should redirect_to(admin_users_path) }
  end

  def post_change_uid
    post :change_uid, :id => 1, :user_uid => { :uid => 'hoge' }
  end
end

describe Admin::UsersController, "POST #create_uid" do
  before do
    admin_login

    @user = stub_model(Admin::User)
    @user.status = 'ACTIVE'
    Admin::User.stub!(:find).with("1").and_return(@user)

    @user_uid = stub_model(Admin::UserUid)
    @user_uids = mock('user_uids')
    @user.stub!(:user_uids).and_return(@user_uids)
  end
  describe "ユーザ名が登録されていない場合" do
    before do
      @user_uids.stub!(:find).and_return(nil)
      @user_uids.stub!(:build).with({ "uid" => 'hoge', "uid_type" => UserUid::UID_TYPE[:username]}).and_return(@user_uid)
    end
    describe "作成に成功する場合" do
      before do
        @user_uid.should_receive(:save).and_return(true)

        post :create_uid, :id => 1, :user_uid => { :uid => 'hoge' }
      end
      it { response.should be_redirect }
      it "flashにメッセージが登録されていること" do
        flash[:notice].should == "User was successfully registered."
      end
    end
    describe "バリデーションエラーの場合" do
      before do
        @user_uid.should_receive(:save).and_return(false)

        post :create_uid, :id => 1, :user_uid => { :uid => 'hoge' }
      end
      it { response.should render_template('create_uid') }
      it "@user_uidが設定されていること" do
        assigns[:user_uid].should == @user_uid
      end
    end
  end
  describe "もう既にユーザ名が登録されていた場合" do
    before do
      @user_uids.stub!(:find).and_return(@user_uid)

      post :create_uid, :id => 1, :user_uid => { :uid => 'hoge' }
    end
    it { response.should redirect_to(admin_user_path(@user)) }
    it "flashにメッセージが登録されていること" do
      flash[:error].should == "User user name has already been registered."
    end
  end
end

describe Admin::UsersController, 'POST /issue_activation_code' do
  before do
    admin_login
  end
  describe '未使用ユーザの場合' do
    before do
      @unused_user = stub_model(Admin::User, :status => 'UNUSED', :email => SkipFaker.email)
      User.should_receive(:issue_activation_codes).and_yield([@unused_user], [])
      post :issue_activation_code
    end
    it 'メール送信した旨のメッセージが設定されてリダイレクトされること' do
      flash[:notice].should_not be_nil
      response.should be_redirect
    end
  end
  describe '未使用ユーザ以外の場合' do
    before do
      @active_user = stub_model(Admin::User, :status => 'ACTIVE')
      User.should_receive(:issue_activation_codes).and_yield([], [@active_user])
      post :issue_activation_code
    end
    it '既に利用開始済みである旨のメッセージが設定されること' do
      flash[:error].should_not be_nil
      response.should be_redirect
    end
  end
end

describe Admin::UsersController, 'POST /issue_password_reset_code' do
  before do
    admin_login
  end
  describe '未使用ユーザの場合' do
    before do
      @user = stub_model(Admin::User, :status => 'UNUSED')
      @user.stub!(:save_without_validation!)
      Admin::User.should_receive(:find).and_return(@user)
    end
    it '未使用ユーザのパスワード再設定コードは発行できない旨のメッセージが設定されること' do
      post :issue_password_reset_code, :id => 1
      flash[:error].should_not be_nil
      response.should be_redirect
    end
  end
  describe '利用開始済みユーザの場合' do
    before do
      @user = stub_model(Admin::User, :status => 'ACTIVE')
      @user.stub!(:save_without_validation!)
      Admin::User.should_receive(:find).and_return(@user)
    end
    describe 'パスワードリセットコード未発行の場合' do
      before do
        @user.should_receive(:reset_auth_token).at_least(:once).and_return(nil)
      end
      it 'パスワード再設定コードの発行処理が行われること' do
        @user.should_receive(:issue_reset_auth_token)
        @user.should_receive(:save_without_validation!)
        post :issue_password_reset_code
      end
    end
    describe 'パスワードリセットコードが期限切れの場合' do
      before do
        @user.should_receive(:reset_auth_token).at_least(:once).and_return('reset_auth_token')
        @user.should_receive(:within_time_limit_of_reset_auth_token?).and_return(false)
      end
      it 'パスワード再設定コードの発行処理が行われること' do
        @user.should_receive(:issue_reset_auth_token)
        @user.should_receive(:save_without_validation!)
        post :issue_password_reset_code
      end
    end
    describe 'パスワードリセットコードが期限内の場合' do
      before do
        @user.should_receive(:reset_auth_token).at_least(:once).and_return('reset_auth_token')
        @user.should_receive(:within_time_limit_of_reset_auth_token?).and_return(true)
      end
      it 'パスワード再設定コードの発行処理が行われないこと' do
        @user.should_not_receive(:issue_reset_auth_token)
        @user.should_not_receive(:save_without_validation!)
        post :issue_password_reset_code
      end
    end
    it 'パスワード再設定URL表示画面に遷移すること' do
      post :issue_password_reset_code
      response.should be_success
    end
  end
end

describe Admin::UsersController, 'POST /lock_actives' do
  before do
    admin_login
    Admin::User.should_receive(:lock_actives).and_return(10)
    post :lock_actives
  end
  it 'xx件のユーザをロックした旨のflashメッセージが設定されること' do
    flash[:notice].should == 'Updated 10 records.'
  end
  it 'ユーザ一覧画面のリダイレクトされること' do
    response.should redirect_to(admin_settings_path(:tab => :security))
  end
end
