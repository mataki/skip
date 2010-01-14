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

describe ShareFileController, 'GET #new' do
  before do
    @user = user_login
    ShareFile.stub!(:get_tags_hash)
    @share_file = stub_model(ShareFile)
    @share_file.stub!(:updatable?).and_return(true)
    ShareFile.stub!(:new).and_return(@share_file)
  end

  describe '作成権限がある場合' do
    before do
      Symbol.should_receive(:get_item_by_symbol).and_return(stub_model(User, :symbol => 'uid:foo'))
      @share_file.should_receive(:updatable?).with(@user).and_return(true)
    end
    it '作成画面に遷移すること' do
      get :new, :owner_symbol => 'uid:owner'
      response.should render_template('new')
    end
  end

  describe '作成権限がない場合' do
    before do
      Symbol.should_receive(:get_item_by_symbol).and_return(stub_model(User, :symbol => 'uid:foo'))
      @share_file.should_receive(:updatable?).with(@user).and_return(false)
    end
    it '作成画面が閉じられること' do
      controller.should_receive(:render_window_close)
      get :new
    end
  end
end

describe ShareFileController, 'GET #create' do
  before do
    user_login
  end
  it 'GETアクセスできないこと(indexにリダイレクトされること)' do
    get :create
    response.should redirect_to(:action => :index)
  end
end

describe ShareFileController, "POST #create" do
  before do
    @current_user = user_login
    @share_file = stub_model(ShareFile)
    @share_file.stub!(:user_id=)
    @share_file.stub!(:publication_type=)
    @share_file.stub!(:publication_symbols_value=)
    @share_file.stub!(:accessed_user=)
    ShareFile.stub!(:new).and_return(@share_file)
  end

  describe 'ファイルが送信されない場合' do
    it '作成画面が閉じられること' do
      controller.should_receive(:render_window_close)
      post :create
    end
    describe "ajax_uploadの場合" do
      it "エラー内容が表示されること" do
        post :create, :ajax_upload => "1"
        json = JSON.parse(response.body)
        json['messages'].should == ['File is mandatory.']
        json['status'].should == '400'
      end
    end
  end

  describe 'ファイルが送信される場合' do
    it '対象共有ファイルのuser_idにアクセスユーザのidが設定されること' do
      @share_file.should_receive(:user_id=).with(@current_user.id)
      post :create, :file => {}
    end
    describe 'ファイルが空の場合' do
      it '作成画面が閉じられること' do
        controller.should_receive(:render_window_close)
        post :create, :file => {}
      end
    end
    describe 'ファイルが空ではない場合' do
      before do
        @share_file.stub!(:save).and_return(true)
        controller.stub!(:analyze_param_publication_type).and_return([])
        @share_file.stub!(:upload_file)
      end
      describe '単一ファイルが送信される場合' do
        before do
          @file1 = mock_uploaed_file({ :original_filename => "file1.png", :content_type => "image/png", :size => 1, :read => "" })
        end
        it '対象共有ファイルのaccessed_userにアクセスユーザが設定されること' do
          @share_file.should_receive(:accessed_user=).with(@current_user)
          post :create, :file => { '1' => @file1 }
        end
        it '対象共有ファイルのファイル名にアップロードファイルのファイル名が設定されること' do
          @share_file.should_receive(:file_name=).with(@file1.original_filename)
          post :create, :file => { '1' => @file1 }
        end
        it '対象共有ファイルのコンテンツタイプにアップロードファイルのコンテンツタイプが設定されること' do
          @share_file.should_receive(:content_type=).with(@file1.content_type.chomp)
          post :create, :file => { '1' => @file1 }
        end
        describe '保存に成功する場合' do
          before do
            @share_file.should_receive(:save).and_return(true)
          end
          it '公開対象となるシンボルが作成されること' do
            controller.stub!(:analyze_param_publication_type).and_return(['sid:allusers'])
            share_file_publications = [stub_model(ShareFilePublication)]
            share_file_publications.should_receive(:create).with(:symbol => 'sid:allusers')
            @share_file.should_receive(:share_file_publications).and_return(share_file_publications)
            post :create, :file => { '1' => @file1 }
          end
          it '実体ファイルがアップロードされること' do
            @share_file.should_receive(:upload_file)
            post :create, :file => { '1' => @file1 }
          end
          it 'ファイルの作成に成功した旨のメッセージが設定されること' do
            post :create, :file => { '1' => @file1 }
            flash[:notice].should == 'File was successfully uploaded.'
          end
          it '作成画面が閉じられること' do
            controller.should_receive(:render_window_close)
            post :create, :file => { '1' => @file1 }
          end
          describe "content_typeが送信されていない場合" do
            before do
              @file1.should_receive(:content_type).and_return(nil)
            end
            it "content_typeには application/octet-stream が設定されること" do
              @share_file.should_receive(:content_type=).with(Types::ContentType::DEFAULT_CONTENT_TYPE)
              post :create, :file => { '1' => @file1 }
            end
          end
        end
        describe '保存に失敗する場合' do
          before do
            @share_file.should_receive(:save).and_return(false)
          end
          it 'flashエラーメッセージが設定されること' do
            stub_flash_now
            post :create, :file => { '1' => @file1 }
            flash[:warn].should == 'Failed to upload file(s).[Successes:0 Failure:1]'
          end
          it 'ファイル毎のエラーメッセージが設定されること' do
            post :create, :file => { '1' => @file1 }
            assigns[:error_messages].size.should == 1
          end
          it '新規作成画面に遷移すること' do
            post :create, :file => { '1' => @file1 }
            response.should render_template('new')
          end
        end
      end
      describe '複数ファイル(2ファイル)が送信される場合' do
        before do
          @file1 = mock_uploaed_file({ :original_filename => "file1.png", :content_type => "image/png", :size => 1, :read => "" })
          @file2 = mock_uploaed_file({ :original_filename => "file2.jpg", :content_type => "image/jpg", :size => 2, :read => "" })
        end
        it '対象共有ファイルのaccessed_userにアクセスユーザが設定されること' do
          @share_file.should_receive(:accessed_user=).with(@current_user).twice
          post :create, :file => { '1' => @file1, '2' => @file2 }
        end
        it '対象共有ファイルのファイル名にアップロードファイルのファイル名が設定されること' do
          @share_file.should_receive(:file_name=).with(@file1.original_filename)
          @share_file.should_receive(:file_name=).with(@file2.original_filename)
          post :create, :file => { '1' => @file1, '2' => @file2 }
        end
        it '対象共有ファイルのコンテンツタイプにアップロードファイルのコンテンツタイプが設定されること' do
          @share_file.should_receive(:content_type=).with(@file1.content_type.chomp)
          @share_file.should_receive(:content_type=).with(@file2.content_type.chomp)
          post :create, :file => { '1' => @file1, '2' => @file2 }
        end
        describe '保存に成功する場合' do
          before do
            @share_file.should_receive(:save).twice.and_return(true)
          end
          it '公開対象となるシンボルが作成されること' do
            controller.stub!(:analyze_param_publication_type).and_return(['sid:allusers'])
            share_file_publications = [stub_model(ShareFilePublication)]
            share_file_publications.should_receive(:create).with(:symbol => 'sid:allusers').twice
            @share_file.should_receive(:share_file_publications).twice.and_return(share_file_publications)
            post :create, :file => { '1' => @file1, '2' => @file2 }
          end
          it '実体ファイルがアップロードされること' do
            @share_file.should_receive(:upload_file).twice
            post :create, :file => { '1' => @file1, '2' => @file2 }
          end
          it 'ファイルの作成に成功した旨のメッセージが設定されること' do
            post :create, :file => { '1' => @file1, '2' => @file2 }
            flash[:notice].should == 'Files were successfully uploaded.'
          end
          it '作成画面が閉じられること' do
            controller.should_receive(:render_window_close)
            post :create, :file => { '1' => @file1, '2' => @file2 }
          end
        end
        describe '保存に失敗する場合' do
          before do
            @share_file.should_receive(:save).twice.and_return(false)
          end
          it 'flashエラーメッセージが設定されること' do
            stub_flash_now
            post :create, :file => { '1' => @file1, '2' => @file2 }
            flash[:warn].should == 'Failed to upload file(s).[Successes:0 Failures:2]'
          end
          it 'ファイル毎のエラーメッセージが設定されること' do
            post :create, :file => { '1' => @file1, '2' => @file2 }
            assigns[:error_messages].size.should == 2
          end
          it '新規作成画面に遷移すること' do
            post :create, :file => { '1' => @file1, '2' => @file2 }
            response.should render_template('new')
          end
        end
      end
    end
  end
end

describe ShareFileController, 'GET #edit' do
  before do
    @user = user_login
    ShareFile.stub!(:get_tags_hash)
  end

  describe '対象の共有ファイルが見つかる場合' do
    before do
      @share_file = stub_model(ShareFile, :publication_type => 'public', :owner_symbol => 'uid:owner')
      ShareFile.should_receive(:find).and_return(@share_file)
    end
    describe '更新権限がある場合' do
      before do
        @share_file.should_receive(:updatable?).with(@user).and_return(true)
      end
      it '編集画面に遷移すること' do
        get :edit
        response.should render_template('edit')
      end
    end
    describe '更新権限がない場合' do
      before do
        @share_file.should_receive(:updatable?).with(@user).and_return(false)
      end
      it '編集画面が閉じられること' do
        controller.should_receive(:render_window_close)
        get :edit
      end
    end
  end

  describe '対象の共有ファイルが見つからない場合' do
    before do
      ShareFile.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
    end
    it '編集画面が閉じられること' do
      controller.should_receive(:render_window_close)
      get :edit
    end
  end
end

describe ShareFileController, 'GET #update' do
  before do
    user_login
  end
  it 'GETアクセスできないこと(indexにリダイレクトされること)' do
    get :update
    response.should redirect_to(:action => :index)
  end
end

describe ShareFileController, 'POST #update' do
  before do
    @current_user = user_login
  end
  describe '対象の共有ファイルが見つかる場合' do
    before do
      @share_file = stub_model(ShareFile, :publication_type => 'public', :owner_symbol => 'uid:owner')
      @share_file_publications = [stub_model(ShareFilePublication)]
      @share_file_publications.stub!(:create)
      @share_file.stub!(:share_file_publications).and_return(@share_file_publications)
      ShareFile.should_receive(:find).and_return(@share_file)
      ShareFile.stub!(:get_tags_hash)
    end
    it '対象共有ファイルのaccessed_userにアクセスユーザが設定されること' do
      @share_file.should_receive(:accessed_user=).with(@current_user)
      post :update, :share_file => {}, :publication_type => 'public'
    end
    describe '保存に成功する場合' do
      before do
        @share_file.should_receive(:update_attributes).and_return(true)
      end
      it '権限テーブルの保存が行われること' do
        @share_file_publications.should_receive(:create)
        post :update, :share_file => {}, :publication_type => 'public'
      end
      it '更新に成功した旨のメッセージが設定されること' do
        post :update, :share_file => {}, :publication_type => 'public'
        flash[:notice].should == 'Updated.'
      end
      it '編集画面が閉じられること' do
        controller.should_receive(:render_window_close)
        post :update, :share_file => {}, :publication_type => 'public'
      end
    end
    describe '保存に失敗する場合' do
      before do
        @share_file.should_receive(:update_attributes).and_return(false)
      end
      it '編集画面に遷移すること' do
        post :update, :share_file => {}
        response.should render_template('edit')
      end
    end
  end
  describe '対象の共有ファイルが見つからない場合' do
    #共通処理で404画面へ遷移する
  end
end

describe ShareFileController, 'GET #destroy' do
  before do
    user_login
  end
  it 'GETアクセスできないこと(indexにリダイレクトされること)' do
    get :destroy
    response.should redirect_to(:action => :index)
  end
end

describe ShareFileController, "POST #destroy" do
  before do
    @user = user_login
  end
  describe "ファイルが見つからなかったとき" do
    before do
      ShareFile.stub!(:find).with("1").and_raise(ActiveRecord::RecordNotFound)
    end
    it "ActiveRecord::RecordNotFoundが発生すること" do
      lambda do
        post :destroy, :id => 1
      end.should raise_error(ActiveRecord::RecordNotFound)
    end
  end
  describe "削除権限がなかった場合" do
    before do
      @share_file = stub_model(ShareFile)
      ShareFile.stub!(:find).with("1").and_return(@share_file)
      @share_file.should_receive(:updatable?).with(@user).and_return(false)
    end
    it '権限チェックエラーとなること' do
      controller.should_receive(:redirect_to_with_deny_auth)
      post :destroy, :id => 1
    end
  end
  describe "削除に成功した場合" do
    before do
      @share_file = stub_model(ShareFile, :owner_symbol_type => "group", :owner_symbol_id => "hoge")
      ShareFile.stub!(:find).with("1").and_return(@share_file)
      @share_file.should_receive(:updatable?).with(@user).and_return(true)
      @share_file.should_receive(:destroy).and_return(@share_file)
      post :destroy, :id => 1
    end
    it { response.should redirect_to(:controller => "group", :action => "hoge", :id => "share_file") }
    it { flash[:notice].should == "File was successfully deleted." }
  end
end

describe ShareFileController, "GET #list" do
  before do
    @user = user_login
  end
  describe "ユーザの共有ファイル一覧を表示している場合" do
    before do
      ShareFile.stub(:paginate).and_return(@share_files = [stub_model(ShareFile)])
    end
    describe "自分の共有ファイルを表示している場合" do
      before do
        User.stub(:find_by_uid).and_return(@user)
        get :list, :uid => "a.user"
      end
      it "set assigns" do
        assigns[:main_menu].should == "My Page"
        assigns[:title].should == "My Page"
        assigns[:tab_menu_option].should == { :uid => @user.uid }
        assigns[:owner_name].should == @user.name
        assigns[:share_files].should == @share_files
      end
      it { response.should render_template("list") }
    end
    describe "他人の共有ファイルを表示している場合" do
      before do
        User.stub(:find_by_uid).with("b_user").and_return(@target_user = mock_model(User, :symbol => 'user:b_user', :uid => 'b_user', :name => "対象ユーザ"))
        get :list, :uid => "b_user"
      end
      it "set assigns" do
        assigns[:main_menu].should == "Users"
        assigns[:title].should == "Mr./Ms. 対象ユーザ"
        assigns[:tab_menu_option].should == { :uid => @target_user.uid }
        assigns[:owner_name].should == @target_user.name
        assigns[:share_files].should == @share_files
      end
      it { response.should render_template("list") }
    end
  end
  describe "グループの共有ファイル一覧を表示している場合" do
    before do
      ShareFile.stub(:paginate).and_return(@share_files = [stub_model(ShareFile)])
      Group.stub(:find_by_gid).with("a_group").and_return(@group = mock_model(Group, :symbol => 'group:a_group', :name => "対象グループ", :gid => "a_group"))
      @group.stub_chain(:group_participations, :find_by_user_id).and_return(@participation = mock('participation'))
      get :list, :gid => "a_group"
    end
    it "set assigns" do
      assigns[:main_menu].should == 'Groups'
      assigns[:title].should == "対象グループ"
      assigns[:tab_menu_option].should == { :gid => @group.gid }
      assigns[:owner_name].should == @group.name
      assigns[:share_files].should == @share_files
    end
    it { response.should render_template("list") }
  end
  describe "対応するユーザやグループが存在しなかった場合" do
    before do
      User.stub(:find_by_uid).and_return(nil)
      Group.stub(:find_by_gid).and_return(nil)
      get :list, :uid => 'foo', :gid => 'bar'
    end
    it "マイページにリダイレクトする" do
      response.should redirect_to(root_url)
    end
    it "Flashが設定されていること" do
      flash[:warn].should == "Specified share file owner does not exist."
    end
  end
end


describe ShareFileController, "GET #download" do
  before do
    @user = user_login
  end
  describe '対象のShareFileが存在する場合' do
    before do
      @share_file = stub_model(ShareFile)
      @full_path = 'example.png'
      @share_file.stub!(:full_path).and_return(@full_path)
      ShareFile.should_receive(:find_by_file_name_and_owner_symbol).and_return(@share_file)
    end
    describe '参照権限がある場合' do
      before do
        @share_file.should_receive(:readable?).with(@user).and_return(true)
      end
      describe 'ダウンロードを許可するファイルの場合' do
        before do
          controller.should_receive(:downloadable?).and_return(true)
        end
        describe '対象となる実体ファイルが存在する場合' do
          before do
            @share_file.stub!(:create_history)
            @controller.stub!(:nkf_file_name)
            @controller.stub!(:send_file)
            File.should_receive(:exist?).with(@full_path).and_return(true)
          end
          it '履歴が作成されること' do
            @share_file.should_receive(:create_history).with(@user.id)
            get :download
          end
          it 'ファイルがダウンロードされること' do
            @controller.should_receive(:send_file).with(@share_file.full_path, anything())
            get :download
          end
        end
        describe '対象となる実体ファイルが存在しない場合' do
          before do
            File.should_receive(:exist?).with(@full_path).and_return(false)
            get :download
          end
          it { flash[:warn].should_not be_nil }
          it { response.should be_redirect }
        end
      end
      describe 'ダウンロードを許可しないファイルの場合' do
        before do
          controller.should_receive(:downloadable?).and_return(false)
          get :download
        end
        it { response.should render_template('confirm_download') }
      end
    end
    describe '参照権限がない場合' do
      before do
        @share_file.should_receive(:readable?).with(@user).and_return(false)
      end
      it '権限チェックエラーとなること' do
        controller.should_receive(:redirect_to_with_deny_auth)
        get :download
      end
    end
  end
  describe '対象のShareFileが存在しない場合' do
    before do
      ShareFile.should_receive(:find_by_file_name_and_owner_symbol).and_return(nil)
    end
    it 'RecordNotFoundがraiseされること' do
      lambda do
        get :download
      end.should raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

describe ShareFileController, '#downloadable?' do
  before do
    controller.stub!(:form_authenticity_token)
  end
  describe 'authenticity_tokenのチェックを行う必要がない場合' do
    before do
      @share_file = stub_model(ShareFile)
      @share_file.stub!(:uncheck_authenticity).and_return(true)
    end
    it 'trueを返すこと' do
      controller.send(:downloadable?, anything(), @share_file).should be_true
    end
  end
  describe 'authenticity_tokenのチェックを行う必要がある場合' do
    before do
      @share_file = stub_model(ShareFile)
      @share_file.stub!(:uncheck_authenticity).and_return(false)
      @valid_authenticity_token = SkipFaker.rand_char
      controller.should_receive(:form_authenticity_token).and_return(@valid_authenticity_token)
    end
    describe 'authenticity_tokenが正しい場合' do
      it 'trueを返すこと' do
        controller.send(:downloadable?, @valid_authenticity_token, @share_file).should be_true
      end
    end
    describe 'authenticity_tokenが間違っている場合' do
      it 'falseを返すこと' do
        controller.send(:downloadable?, nil, @share_file).should be_false
      end
    end
  end
end

describe ShareFileController, 'GET #download_history_as_csv' do
  before do
    user_login
  end
  it 'GETアクセスできないこと(indexにリダイレクトされること)' do
    get :download_history_as_csv
    response.should redirect_to(:action => :index)
  end
end

describe ShareFileController, 'POST #download_history_as_csv' do
  before do
    @user = user_login
  end
  describe '対象のShareFileが存在する場合' do
    before do
      @csv_text, @file_name = 'test,test', 'test.csv'
      @share_file = stub_model(ShareFile)
      @share_file.stub!(:get_accesses_as_csv).and_return(@csv_text, @file_name)
      ShareFile.should_receive(:find).and_return(@share_file)
    end
    describe '権限のあるファイルの場合' do
      before do
        @share_file.should_receive(:updatable?).with(@user).and_return(true)
      end
      it 'csvファイルがdownloadされること' do
        controller.stub!(:nkf_file_name)
        controller.should_receive(:send_data).with(@csv_text, anything())
        post :download_history_as_csv
      end
    end
    describe '権限のないファイルの場合' do
      before do
        @share_file.should_receive(:updatable?).with(@user).and_return(false)
      end
      it '権限チェックエラーとなること' do
        controller.should_not_receive(:send_data)
        controller.should_receive(:redirect_to_with_deny_auth)
        post :download_history_as_csv
      end
    end
  end
end

describe ShareFileController, 'GET #clear_download_history' do
  before do
    user_login
  end
  it 'GETアクセスできないこと(indexにリダイレクトされること)' do
    get :clear_download_history
    response.should redirect_to(:action => :index)
  end
end

describe ShareFileController, 'POST #clear_download_history' do
  before do
    @user = user_login
  end
  describe '対象の共有ファイルが見つかる場合' do
    before do
      @share_file = stub_model(ShareFile)
      @share_file_accesses = [stub_model(ShareFileAccess)]
      @share_file_accesses.stub!(:clear)
      @share_file.stub!(:share_file_accesses).and_return(@share_file_accesses)
      ShareFile.should_receive(:find).and_return(@share_file)
    end
    describe '更新権限がある場合' do
      before do
        @share_file.should_receive(:updatable?).with(@user).and_return(true)
      end
      it 'ダウンロード履歴がクリアされること' do
        @share_file_accesses.should_receive(:clear)
        post :clear_download_history
      end
      it '処理に成功すること' do
        post :clear_download_history
        response.should be_success
      end
      it '処理に成功した旨のメッセージが返却されること' do
        post :clear_download_history
        response.body.should == 'Download history was successfully deleted.'
      end
    end
    describe '更新権限がない場合' do
      before do
        @share_file.should_receive(:updatable?).with(@user).and_return(false)
      end
      it 'ダウンロード履歴がクリアされないこと' do
        @share_file_accesses.should_not_receive(:clear)
        post :clear_download_history
      end
      it '403が返却されること' do
        post :clear_download_history
        response.code.should == '403'
      end
      it '権限がない旨のメッセージが返却されること' do
        post :clear_download_history
        response.body.should == 'Operation unauthorized.'
      end
    end
  end
  describe '対象の共有ファイルが見つからない場合' do
    #共通処理で404画面へ遷移する
  end
end

describe ShareFileController, ".nkf_file_name" do
  before do
    @file_name = "ファイル名"
  end
  describe "IEの場合" do
    before do
      controller.stub_chain(:request, :headers).and_return('HTTP_USER_AGENT' => "MSIE")
    end
    it "NKFで文字コードを変換すること" do
      NKF.should_receive(:nkf).with('-Ws', @file_name)
      controller.send(:nkf_file_name, @file_name)
    end
  end
  describe "IE以外の場合" do
    before do
      controller.stub_chain(:request, :headers).and_return('HTTP_USER_AGENT' => "MSIE Opera")
    end
    it "NKFで文字コードを変換すること" do
      NKF.should_not_receive(:nkf)
      controller.send(:nkf_file_name, @file_name)
    end
  end
end
