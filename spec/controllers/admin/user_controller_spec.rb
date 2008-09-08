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
    get :new
  end
  it {assigns[:user].should_not be_nil}
  it {assigns[:user_profile].should_not be_nil}
  it {assigns[:user_uid].should_not be_nil}
  it {assigns[:topics].should_not be_nil}
  it {response.should be_success}
end

describe Admin::UsersController, 'POST /create' do
  before do
    admin_login
    @user = stub_model(Admin::User)
    @user.stub!(:save!)
    @user_profile = stub_model(Admin::UserProfile)
    @user_uid = stub_model(Admin::UserUid)
    Admin::User.stub!(:make_new_user).and_return([@user, @user_profile, @user_uid])
  end
  describe 'ユーザの登録に成功する場合' do
    it 'Admin::Userが作成されること' do
      @user.should_receive(:save!)
      Admin::User.should_receive(:make_new_user).and_return([@user, @user_profile, @user_uid])
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
    @user_profile = stub_model(Admin::UserProfile)
    @user.stub!(:user_profile).and_return(@user_profile)
    @user_uid = stub_model(Admin::UserUid)
    @user.stub!(:master_user_uid).and_return(@user_uid)
    get :edit
  end
  it {assigns[:user].should_not be_nil}
  it {assigns[:user_profile].should_not be_nil}
  it {assigns[:user_uid].should_not be_nil}
  it {assigns[:topics].should_not be_nil}
  it {response.should be_success}
end

describe Admin::UsersController, 'POST /update' do
end

describe Admin::UsersController, 'GET /first' do
  describe '有効なactivation_codeの場合' do
    before do
      controller.should_receive(:valid_activation_code?).and_return(true)
      get :first
    end
    it {response.should be_success}
    it {assigns[:user].should_not be_nil}
    it {assigns[:user_profile].should_not be_nil}
    it {assigns[:user_uid].should_not be_nil}
  end
end

describe Admin::UsersController, 'POST /first' do
  describe '有効なactivation_codeの場合' do
    before do
      controller.stub!(:valid_activation_code?).and_return(true)
      @user = stub_model(Admin::User)
      @user_profile = stub_model(Admin::UserProfile)
      @user_uid = stub_model(Admin::UserUid)
      @activation = stub_model(Activation)
      @user.stub!(:user_access=)
      Admin::User.stub!(:make_user).and_return([@user, @user_profile, @user_uid])
    end
    describe '管理者ユーザの登録に成功する場合' do
      # ユーザが作成されること
      before do
        @user.should_receive(:user_access=)
        @user.should_receive(:save!)
        Admin::User.should_receive(:make_user).and_return([@user, @user_profile, @user_uid])
        @activation.should_receive(:update_attributes).with({:code => nil})
        Activation.should_receive(:find_by_code).and_return(@activation)
        post :first, {:user => {"name"=>"管理者", "password_confirmation"=>"[FILTERED]", "password"=>"[FILTERED]"}, :user_profile => {"email"=>"admin@skip.org", "section"=>"管理部"}, :user_uid => {:uid => 'admin'}}
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
      post :first
    end
    it {response.code.should == '403'}
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
      controller.should_receive(:valid_csv?).and_return(false)
      post :import
    end
    it { response.should render_template('import') }
    it { assigns[:users].should_not be_nil }
  end
  describe '正常なファイルの場合' do
    before do
      @new_user = stub_model(Admin::User)
      @new_user_profile = stub_model(Admin::UserProfile)
      @new_user_uid = stub_model(Admin::UserUid)
      @edit_user = stub_model(Admin::User)
      @edit_user_profile = stub_model(Admin::UserProfile)
      @edit_user_uid = stub_model(Admin::UserUid)
      @new_user.stub!(:save!)
      @edit_user.stub!(:save!)
      @edit_user_profile.stub!(:save!)
      @edit_user_uid.stub!(:save!)
      controller.should_receive(:valid_csv?).and_return(true)
    end
    describe '1件が新規、1件が既存レコードの場合' do
      before do
        @new_user.stub!(:new_record?).and_return(true)
        @edit_user.stub!(:new_record?).and_return(false)
        Admin::User.should_receive(:make_users).and_return([[@new_user, @new_user_profile, @new_user_uid], [@edit_user, @edit_user_profile, @edit_user_uid]])
      end
      it '新規レコードはUserのみ、既存レコードはUser, UserProfile, UserUidの各々で保存されること' do
        @new_user.should_receive(:save!)
        @edit_user.should_receive(:save!)
        @edit_user_profile.should_receive(:save!)
        @edit_user_uid.should_receive(:save!)
        post :import
      end
      
      it { post :import; flash[:notice].should_not be_nil }
      it { post :import; response.should redirect_to(admin_users_path) }
    end
    describe 'invalidなレコードが含まれる場合' do
      before do
        @new_user.stub!(:new_record?).and_return(true)
        @new_user.should_receive(:save!).and_raise(mock_record_invalid)
        @new_user.should_receive(:valid?)
        Admin::User.should_receive(:make_users).and_return([@new_user, @new_user_profile, @new_user_uid])
        post :import
      end
      it { response.should render_template('import') }
    end
  end
end

describe Admin::UsersController, '#valid_csv' do
  describe 'ファイルがnil又は空の場合' do
    before do
      @file = nil
      controller.send(:valid_csv?, @file)
    end
    it { flash[:error].should_not be_nil }
  end
  describe 'ファイルサイズが0の場合' do
    before do
      @file = mock_csv_file(:size => 0)
      controller.send(:valid_csv?, @file)
    end
    it { flash[:error].should_not be_nil }
  end
  describe 'ファイルサイズが1MBを超える場合' do
    before do
      @file = mock_csv_file(:size => 1.megabyte + 1)
      controller.send(:valid_csv?, @file)
    end
    it { flash[:error].should_not be_nil }
  end
  describe 'ファイルのContent-typeがcsv以外の場合' do
    before do
      @file = mock_csv_file(:content_type => 'image/jpeg')
      controller.send(:valid_csv?, @file)
    end
    it { flash[:error].should_not be_nil }
  end
  describe 'ファイルのContent-typeがcsvの場合' do
    it "application/x-csvを渡した時、tureを返すこと" do
      controller.send(:valid_csv?, mock_csv_file(:content_type => 'application/x-csv')).should be_true
    end
    it "text/csvを渡した時、trueを返すこと" do
      controller.send(:valid_csv?, mock_csv_file(:content_type => 'text/csv')).should be_true
    end
  end
end

def mock_csv_file(options = {})
  file = mock(ActionController::UploadedStringIO)
  size = options[:size] ? options[:size] : 1.kilobyte
  file.stub!(:size).and_return(size)
  content_type = options[:content_type] ? options[:content_type] : 'text/csv'
  file.stub!(:content_type).and_return(content_type)
  file
end
