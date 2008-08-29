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

describe Admin::AccountsController do
  before do
    admin_login
  end
  describe "handling GET /admin_accounts" do

    before(:each) do
      @account = mock_model(Admin::Account)
      @page = mock('page')
      controller.should_receive(:paginate).and_return([@page, [@account]])
    end

    def do_get
      get :index
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render index template" do
      do_get
      response.should render_template('index')
    end

    it "should assign the found admin_accounts for the view" do
      do_get
      assigns[:accounts].should == [@account]
    end
  end

  describe "handling GET /admin_accounts.xml" do

    before(:each) do
      @account = mock_model(Admin::Account)
      @accounts = [@account]
      @accounts.stub!(:to_xml).and_return('XML')
      controller.should_receive(:paginate).and_return([@page, @accounts])
    end

    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :index
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render the found admin_accounts as xml" do
      @accounts.should_receive(:to_xml).and_return("XML")
      do_get
      response.body.should == "XML"
    end
  end

  describe "handling GET /admin_accounts/1" do

    before(:each) do
      @account = mock_model(Admin::Account)
      Admin::Account.stub!(:find).and_return(@account)
    end

    def do_get
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render show template" do
      do_get
      response.should render_template('show')
    end

    it "should find the account requested" do
      Admin::Account.should_receive(:find).with("1").and_return(@account)
      do_get
    end

    it "should assign the found account for the view" do
      do_get
      assigns[:account].should equal(@account)
    end
  end

  describe "handling GET /admin_accounts/1.xml" do

    before(:each) do
      @account = mock_model(Admin::Account, :to_xml => "XML")
      Admin::Account.stub!(:find).and_return(@account)
    end

    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should find the account requested" do
      Admin::Account.should_receive(:find).with("1").and_return(@account)
      do_get
    end

    it "should render the found account as xml" do
      @account.should_receive(:to_xml).and_return("XML")
      do_get
      response.body.should == "XML"
    end
  end

  describe "handling GET /admin_accounts/new" do

    before(:each) do
      @account = mock_model(Admin::Account)
      Admin::Account.stub!(:new).and_return(@account)
    end

    def do_get
      get :new
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render new template" do
      do_get
      response.should render_template('new')
    end

    it "should create an new account" do
      Admin::Account.should_receive(:new).and_return(@account)
      do_get
    end

    it "should not save the new account" do
      @account.should_not_receive(:save)
      do_get
    end

    it "should assign the new account for the view" do
      do_get
      assigns[:account].should equal(@account)
    end
  end

  describe "handling GET /admin_accounts/1/edit" do

    before(:each) do
      @account = mock_model(Admin::Account)
      Admin::Account.stub!(:find).and_return(@account)
    end

    def do_get
      get :edit, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render edit template" do
      do_get
      response.should render_template('edit')
    end

    it "should find the account requested" do
      Admin::Account.should_receive(:find).and_return(@account)
      do_get
    end

    it "should assign the found Admin::Account for the view" do
      do_get
      assigns[:account].should equal(@account)
    end
  end

  describe "handling POST /admin_accounts" do

    before(:each) do
      @account = mock_model(Admin::Account, :to_param => "1")
      Admin::Account.stub!(:new).and_return(@account)
    end

    describe "with successful save" do

      def do_post
        @account.should_receive(:save).and_return(true)
        post :create, :admin_account => {}
      end

      it "should create a new account" do
        Admin::Account.should_receive(:new).with({}).and_return(@account)
        do_post
      end

      it "should redirect to the new account" do
        do_post
        response.should redirect_to(admin_account_url("1"))
      end

    end

    describe "with failed save" do

      def do_post
        @account.should_receive(:save).and_return(false)
        post :create, :account => {}
      end

      it "should re-render 'new'" do
        do_post
        response.should render_template('new')
      end

    end
  end

  describe "handling PUT /admin_accounts/1" do

    before(:each) do
      @account = mock_model(Admin::Account, :to_param => "1")
      Admin::Account.stub!(:find).and_return(@account)
    end

    describe "with successful update" do

      def do_put
        @account.should_receive(:update_attributes).and_return(true)
        put :update, :id => "1"
      end

      it "should find the account requested" do
        Admin::Account.should_receive(:find).with("1").and_return(@account)
        do_put
      end

      it "should update the found account" do
        do_put
        assigns(:account).should equal(@account)
      end

      it "should assign the found account for the view" do
        do_put
        assigns(:account).should equal(@account)
      end

      it "should redirect to the account" do
        do_put
        response.should redirect_to(admin_account_url("1"))
      end

    end

    describe "with failed update" do

      def do_put
        @account.should_receive(:update_attributes).and_return(false)
        put :update, :id => "1"
      end

      it "should re-render 'edit'" do
        do_put
        response.should render_template('edit')
      end

    end
  end

  describe "handling DELETE /admin_accounts/1" do

    before(:each) do
      @account = mock_model(Admin::Account, :destroy => true)
      Admin::Account.stub!(:find).and_return(@account)
    end

    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the account requested" do
      Admin::Account.should_receive(:find).with("1").and_return(@account)
      do_delete
    end

    it "should call destroy on the found account" do
      @account.should_receive(:destroy)
      do_delete
    end

    it "should redirect to the admin_accounts list" do
      do_delete
      response.should redirect_to(admin_accounts_url)
    end
  end
end

describe Admin::AccountsController do
  before do
    admin_login
  end

  describe "GET index" do
    describe "条件がない場合" do
      before do
        @accounts = (1..3).map{|i| mock_model(Admin::Account)}
        @pages = mock('pages')
        controller.should_receive(:paginate).and_return([@pages,@accounts])
        get :index
      end
      it "@accountsが設定されていること" do
        assigns[:accounts].should equal(@accounts)
      end

      it "indexがレンダリングされること" do
        response.should render_template('admin/accounts/index')
      end
    end

    describe "検索条件がある場合" do
      before do
        @query = 'hoge'
        @accounts = (1..3).map{|i| mock_model(Admin::Account)}
        conditions = [Admin::Account.search_colomns, {:lqs => SkipUtil.to_lqs(@query)}]
        @pages = mock('pages')
        controller.should_receive(:paginate).and_return([@pages,@accounts])
        get :index, :query => @query
      end

      it "@accountsが設定されていること" do
        assigns[:accounts].should equal(@accounts)
      end

      it "@queryが設定されていること" do
        assigns[:query].should equal(@query)
      end
    end
  end
end

describe Admin::AccountsController, 'GET /import' do
  before do
    admin_login
    get :import
  end
  it { response.should render_template('import') }
  it { assigns[:accounts].should_not be_nil }
end

describe Admin::AccountsController, 'POST /import' do
  before do
    admin_login
  end
  describe '不正なファイルの場合' do
    before do
      controller.should_receive(:valid_csv?).and_return(false)
      post :import
    end
    it { response.should render_template('import') }
    it { assigns[:accounts].should_not be_nil }
  end
  describe '正常なファイルの場合' do
    before do
      controller.should_receive(:valid_csv?).and_return(true)
    end
    describe '1件が新規、1件が既存レコードの場合' do
      before do
        new_account = mock_model(Admin::Account)
        new_account.stub!(:new_record?).and_return(true)
        new_account.should_receive(:save!)
        edit_account = mock_model(Admin::Account)
        edit_account.stub!(:new_record?).and_return(false)
        edit_account.should_receive(:save!)
        Admin::Account.should_receive(:make_accounts).and_return([new_account, edit_account])
        post :import
      end
      it { flash[:notice].should_not be_nil }
      it { response.should redirect_to(admin_accounts_path) }
    end
    describe 'invalidなレコードが含まれる場合' do
      before do
        new_account = mock_model(Admin::Account)
        new_account.stub!(:new_record?).and_return(true)
        new_account.should_receive(:save!).and_raise(mock_record_invalid)
        new_account.should_receive(:valid?)
        Admin::Account.should_receive(:make_accounts).and_return([new_account])
        post :import
      end
      it { response.should render_template('import') }
    end
  end
end

describe Admin::AccountsController, '#valid_csv' do
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
