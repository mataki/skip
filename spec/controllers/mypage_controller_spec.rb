# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
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

describe MypageController, 'GET #welcome' do
  before do
    user_login
  end
  it 'アンテナボックスに必要な情報が設定されること' do
    controller.should_receive(:setup_for_antenna_box)
    get :welcome
  end
  it 'welcomeに遷移すること' do
    get :welcome
    response.should render_template('welcome')
  end
end

describe MypageController, 'mypage > home 関連' do
  describe MypageController, 'GET #index' do
    before do
      @current_user = user_login
      @current_user_info = {:using_day => 1}
      @current_user.stub!(:info).and_return(@current_user_info)
      controller.stub!(:recent_day).and_return(7)
    end
    # ============================================================
    #  left side area
    # ============================================================
    it 'アンテナボックスに必要な情報が設定されること' do
      controller.should_receive(:setup_for_antenna_box)
      get :index
    end
    # ============================================================
    #  right side area
    # ============================================================
    it '日付情報が設定されること' do
      controller.should_receive(:parse_date).and_return([2009, 1, 2])
      get :index
      assigns[:year].should == 2009
      assigns[:month].should == 1
      assigns[:day].should == 2
    end
    it '指定月の記事が存在する日をキー、記事数を値としたハッシュが設定されること' do
      controller.should_receive(:parse_date).and_return([2009, 1, 2])
      @entry_count_hash = {}
      controller.should_receive(:get_entry_count).with(2009, 1).and_return(@entry_count_hash)
      get :index
      assigns[:entry_count_hash].should == @entry_count_hash
    end
    it '最近登録されたグループが設定されること' do
      @recent_groups = [stub_model(Group)]
      Group.should_receive(:all).and_return(@recent_groups)
      get :index
      assigns[:recent_groups].should == @recent_groups
    end
    it '最近登録されたユーザが設定されること' do
      @recent_users = [stub_model(User)]
      User.should_receive(:all).and_return(@recent_users)
      get :index
      assigns[:recent_users].should == @recent_users
    end

    # ============================================================
    #  main area top
    # ============================================================
    it 'システムからの連絡が設定されること' do
      @system_messages = mock('system_messages')
      controller.should_receive(:system_messages).and_return(@system_messages)
      get :index
      assigns[:system_messages].should == @system_messages
    end
    it 'お知らせ, 承認待ちの一覧が設定されること' do
      @waiting_groups = [stub_model(Group)]
      Group.should_receive(:find_waitings).with(@current_user.id).and_return(@waiting_groups)
      get :index
      assigns[:waiting_groups].should == @waiting_groups
    end
    it 'あなたへの連絡(公開, 未読/既読は関係なし、最近のもののみ)が設定されること' do
      @important_your_messages = mock('important_your_messages')
      controller.should_receive(:important_your_messages).and_return(@important_your_messages)
      get :index
      assigns[:important_your_messages].should == @important_your_messages
    end
    it 'あなたへの連絡(非公開, 未読のもののみ)が設定されること' do
      @mail_your_messages = mock('mail_your_messages')
      controller.should_receive(:mail_your_messages).and_return(@mail_your_messages)
      get :index
      assigns[:mail_your_messages].should == @mail_your_messages
    end
    # メインエリア中央
    it 'みんなからの質問が設定されること' do
      @questions = {}
      controller.should_receive(:find_questions_as_locals).with(:recent_day => 7, :per_page => 5).and_return(@questions)
      get :index
      assigns[:questions].should == @questions
    end
    it '最近の人気記事が設定されること' do
      @access_blogs = {}
      controller.should_receive(:find_access_blogs_as_locals).with(:per_page => 8).and_return(@access_blogs)
      get :index
      assigns[:access_blogs].should == @access_blogs
    end
    it 'ユーザの公開記事が設定されること' do
      @recent_blogs = {}
      controller.should_receive(:find_recent_blogs_as_locals).with(:per_page => 8).and_return(@recent_blogs)
      get :index
      assigns[:recent_blogs].should == @recent_blogs
    end
    it 'グループの公開記事が設定されること' do
      @recent_bbs = mock('recent_bss')
      controller.should_receive(:recent_bbs).and_return(@recent_bbs)
      get :index
      assigns[:recent_bbs].should == @recent_bbs
    end
    it '最新のブックマークが設定されること' do
      @bookmarks = [stub_model(Bookmark)]
      Bookmark.should_receive(:find_visible).with(5, 7).and_return(@bookmarks)
      get :index
      assigns[:bookmarks].should == @bookmarks
    end
  end

  describe MypageController, 'GET #entries' do
    before do
      user_login
    end
    describe 'list_typeが送信されない場合' do
      before do
        get :entries
      end
      it '記事検索画面に遷移すること' do
        response.should redirect_to({:controller => 'search', :action => 'entry_search'})
      end
    end
    describe 'list_typeが送信される場合' do
      describe '想定外のパラメタの場合' do
        before do
          controller.should_receive(:valid_list_types).and_return(['questions'])
          get :entries, :list_type => 'hoge'
        end
        it '404ページへ遷移すること' do
          response.code.should == '404'
        end
      end
      describe '想定内のパラメタの場合' do
        before do
          @id_name = 'id_name'
          @title_icon = 'title_icon'
          @title_name = 'title_name'
          @entries_pages = mock('entries_pages')
          @entries = [stub_model(BoardEntry)]
          @symbol2name_hash = mock('symbol2name_hash')
          locals = {
            :id_name => @id_name,
            :title_icon => @title_icon,
            :title_name => @title_name,
            :pages => @entries_pages,
            :pages_obj => @entries,
            :per_page => 20,
            :symbol2name_hash => @symbol2name_hash
          }
          controller.should_receive(:find_as_locals).and_return(locals)
          controller.should_receive(:valid_list_types).and_return(['questions'])
        end
        it 'アンテナボックスに必要な情報が設定されること' do
          controller.should_receive(:setup_for_antenna_box)
          get :entries, :list_type => 'questions'
        end
        it 'id_nameが設定されること' do
          get :entries, :list_type => 'questions'
          assigns[:id_name].should == @id_name
        end
        it 'タイトルアイコンが設定されること' do
          get :entries, :list_type => 'questions'
          assigns[:title_icon].should == @title_icon
        end
        it 'タイトルが設定されること' do
          get :entries, :list_type => 'questions'
          assigns[:title_name].should == @title_name
        end
        it '記事一覧が設定されること' do
          get :entries, :list_type => 'questions'
          assigns[:entries_pages].should == @entries_pages
          assigns[:entries].should == @entries
        end
        it '記事の所有者のシンボルと名称のhashが設定されること(記事所有者へのリンクに使う)' do
          get :entries, :list_type => 'questions'
          assigns[:symbol2name_hash].should == @symbol2name_hash
        end
        it 'entriesに遷移すること' do
          get :entries, :list_type => 'questions'
          response.should render_template('entries')
        end
      end
    end
  end

  describe MypageController, 'GET #entries_by_date' do
    before do
      user_login
      controller.stub!(:setup_for_antenna_box)
      controller.stub!(:parse_date).and_return([2009, 1, 2])
      controller.stub!(:find_entries_at_specified_date)
      controller.stub!(:first_entry_day_after_specified_date)
      controller.stub!(:last_entry_day_before_specified_date)
    end
    it 'アンテナボックスに必要な情報が設定されること' do
      controller.should_receive(:setup_for_antenna_box)
      get :entries_by_date
    end
    it '日付情報が設定されること' do
      controller.should_receive(:parse_date).and_return([2009, 1, 2])
      get :entries_by_date
      assigns[:selected_day].should == Date.new(2009, 1, 2)
    end
    it '指定日の記事一覧が設定されること' do
      entries = mock([stub_model(BoardEntry)])
      controller.should_receive(:find_entries_at_specified_date).and_return(entries)
      get :entries_by_date
      assigns[:entries].should == entries
    end
    it '指定日移行で最初に記事が存在する日が設定されること' do
      next_day = mock('next_day')
      controller.should_receive(:first_entry_day_after_specified_date).and_return(next_day)
      get :entries_by_date
      assigns[:next_day].should == next_day
    end
    it '指定日以前で最後に記事が存在する日が設定されること' do
      prev_day = mock('prev_day')
      controller.should_receive(:last_entry_day_before_specified_date).and_return(prev_day)
      get :entries_by_date
      assigns[:prev_day].should == prev_day
    end
    it 'entries_by_dateに遷移すること' do
      get :entries_by_date
      response.should render_template('entries_by_date')
    end
  end

  describe MypageController, 'GET #entries_by_antenna' do
    before do
      user_login
      @antenna_entry = stub(MypageController::AntennaEntry)
      @antenna_entry.stub!(:title=)
      @antenna_entry.stub!(:need_search?).and_return(false)
      @antenna_entry.stub!(:conditions).and_return({:conditions => [['']], :include => []})
      controller.stub!(:antenna_entry).and_return(@antenna_entry)
      controller.stub!(:antenna_entry_title)
      controller.stub!(:unread_entry_id_hash_with_user_reading)
      @entries_pages = mock('entries_pages')
      @entries = [stub_model(BoardEntry)]
      controller.stub!(:paginate).and_return([@entries_pages, @entries])
    end
    it 'アンテナボックスに必要な情報が設定されること' do
      controller.should_receive(:setup_for_antenna_box)
      get :entries_by_antenna
    end
    it '@antenna_entryが設定されること' do
      controller.should_receive(:antenna_entry).with(params[:antenna_id], params[:read]).and_return(@antenna_entry)
      get :entries_by_antenna
      assigns[:antenna_entry].should == @antenna_entry
    end
    it '@antenna_entryのタイトルが設定されること' do
      @antenna_entry.should_receive(:title=).with('title')
      controller.should_receive(:antenna_entry_title).with(@antenna_entry).and_return('title')
      get :entries_by_antenna
    end
    describe '記事を検索する場合' do
      before do
        @antenna_entry.should_receive(:need_search?).and_return(true)
      end
      it '記事一覧が設定されること' do
        @conditions = mock('conditions')
        @include = ['include'] | [:user, :state]
        condition_params = {:conditions => @conditions, :include => @include}
        @antenna_entry.should_receive(:conditions).and_return(condition_params)
        controller.should_receive(:paginate).with(:board_entry, :per_page => 20, :order => anything(),
                                                  :conditions => condition_params[:conditions], :include => @include).and_return([@entries_pages, @entries])
        get :entries_by_antenna, :read => 'true'
        assigns[:entries_pages].should == @entries_pages
        assigns[:entries].should == @entries
      end
      it '未読状態を保持するhashが設定されること(記事の既読/未読切り替えチェックボックスに使う)' do
        @entries = [stub_model(BoardEntry, :id => 99), stub_model(BoardEntry, :id => 999)]
        controller.stub!(:paginate).and_return([@entries_pages, @entries])
        @user_unreadings = mock('user_unreadings')
        controller.should_receive(:unread_entry_id_hash_with_user_reading).with([99, 999]).and_return(@user_unreadings)
        get :entries_by_antenna
        assigns[:user_unreadings].should == @user_unreadings
      end
      it '記事の所有者のシンボルと名称のhashが設定されること(記事所有者へのリンクに使う)' do
        @symbol2name_hash = mock('symbol2name_hash')
        BoardEntry.should_receive(:get_symbol2name_hash).with(@entries).and_return(@symbol2name_hash)
        get :entries_by_antenna
        assigns[:symbol2name_hash].should == @symbol2name_hash
      end
    end
    describe '記事を検索しない場合' do
      before do
        @antenna_entry.should_receive(:need_search?).and_return(false)
        get :entries_by_antenna
      end
      it { assigns[:entries_pages].should == nil }
      it { assigns[:entries].should == nil }
      it { assigns[:user_unreadings].should == nil }
      it { assigns[:symbol2name_hash] == nil }
    end
    it 'entries_by_antennaに遷移すること' do
      get :entries_by_antenna
      response.should render_template('entries_by_antenna')
    end
  end
  describe MypageController, '#antenna_entry' do
    before do
      @controller = MypageController.new
      @user = stub_model(User)
      @controller.stub!(:current_user).and_return(@user)
    end
    describe '第一引数がnilの場合' do
      before do
        @antenna_entry = stub('antenna_entry')
        MypageController::AntennaEntry.should_receive(:new).with(@user, true).and_return(@antenna_entry)
      end
      it 'AntennaEntryのインスタンスが返ること' do
        @controller.send!(:antenna_entry, nil, true).should == @antenna_entry
      end
    end
    describe '第一引数が空の場合' do
      before do
        @antenna_entry = stub('antenna_entry')
        MypageController::AntennaEntry.should_receive(:new).with(@user, true).and_return(@antenna_entry)
      end
      it 'AntennaEntryのインスタンスが返ること' do
        @controller.send!(:antenna_entry, '', true).should == @antenna_entry
      end
    end
    describe '第一引数が数値に解釈できる文字列の場合' do
      before do
        @antenna_entry = stub('antenna_entry')
        @key = '1'
        MypageController::UserAntennaEntry.should_receive(:new).with(@user, @key.to_i, true).and_return(@antenna_entry)
      end
      it 'UserAntennaEntryのインスタンスが返ること' do
        @controller.send!(:antenna_entry, @key, true).should == @antenna_entry
      end
    end
    describe '第一引数が数値に解釈できない文字列の場合' do
      before do
        @antenna_entry = stub('antenna_entry')
      end
      describe 'システムアンテナとして有効な文字列の場合' do
        before do
          @key = 'message'
          MypageController::SystemAntennaEntry.should_receive(:new).with(@user, @key, true).and_return(@antenna_entry)
        end
        it 'SystemAntennaEntryのインスタンスが返ること' do
          @controller.send!(:antenna_entry, @key, true).should == @antenna_entry
        end
      end
      describe 'システムアンテナとして無効な文字列の場合' do
        it 'RecordNotFoundがraiseされること' do
          lambda do
            @controller.send!(:antenna_entry, 'invalid', true)
          end.should raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe MypageController::AntennaEntry do
    before do
      @current_user = stub_model(User)
      @antenna_entry = MypageController::AntennaEntry.new(@current_user)
    end
    describe '#initialize' do
      it 'keyがnilであること' do
        @antenna_entry.key.should be_nil
      end
    end
    describe '#need_search?' do
      it { @antenna_entry.need_search?.should be_true }
    end
  end

  describe MypageController::SystemAntennaEntry do
    before do
      @current_user = stub_model(User)
      @antenna_entry = MypageController::SystemAntennaEntry.new(@current_user, 'message')
    end
    describe '#need_search?' do
      describe 'keyがgroupの場合' do
        before do
          @antenna_entry = MypageController::SystemAntennaEntry.new(@current_user, 'group')
        end
        describe '指定ユーザがグループに所属している場合' do
          before do
            @current_user.should_receive(:group_symbols).and_return([:skip_dev])
          end
          it 'trueが返ること' do
            @antenna_entry.need_search?.should be_true
          end
        end
        describe '指定ユーザがグループに所属していない場合' do
          before do
            @current_user.should_receive(:group_symbols).and_return([])
          end
          it 'falseが返ること' do
            @antenna_entry.need_search?.should be_false
          end
        end
      end
      describe 'keyがgroup以外の場合' do
        before do
          @antenna_entry = MypageController::SystemAntennaEntry.new(@current_user, 'message')
        end
        it 'trueが返ること' do
          @antenna_entry.need_search?.should be_true
        end
      end
    end
  end
end

describe MypageController, 'mypage > manage(管理) 関連' do
  describe MypageController, 'POST #update_profile' do
    before do
      @user = user_login
      @profiles = (1..2).map{|i| stub_model(UserProfileValue, :save! => true, :valid? => true)}
      @user.stub!(:find_or_initialize_profiles).and_return(@profiles)
    end
    describe '保存に成功する場合' do
      before do
        @user.stub!(:attributes=)
        @user.should_receive(:save!)
      end

      it "userにパラメータからの値が設定されること" do
        @user.should_receive(:attributes=)
        post_update_profile
      end
      it "profileが設定されること" do
        @user.should_receive(:find_or_initialize_profiles).with({"1"=>"ほげ", "2"=>"ふが"}).and_return(@profiles)
        post_update_profile
      end
      it "profileがそれぞれ保存されること" do
        @profiles.each{ |profile| profile.should_receive(:save!) }
        post_update_profile
      end
      it "自分のプロフィール表示画面にリダイレクトされること" do
        post_update_profile
        response.should redirect_to(:action => 'profile')
      end
      it "flashメッセージ「ユーザ情報の更新に成功しました。」と登録されること" do
        post_update_profile
        flash[:notice].should == "ユーザ情報の更新に成功しました。"
      end
      def post_update_profile
        post :update_profile, {"user" => {"section"=>"開発"}, "profile_value" => {"1"=>"ほげ", "2"=>"ふが"}}
      end
    end
    describe '保存に失敗する場合' do
      before do
        @user.should_receive(:save!).and_raise(mock_record_invalid)
        controller.stub!(:current_user).and_return(@user)
      end
      it "編集画面を再度表示すること" do
        post :update_profile
        response.should render_template('mypage/_manage_profile')
      end
      it "２つのプロフィールにエラーが設定されている場合、２つのバリデーションエラーが設定されること" do
        errors = mock('errors', :full_messages => ["バリデーションエラーです"])
        @profiles.map do |profile|
          profile.stub!(:valid?).and_return(false)
          profile.stub!(:errors).and_return(errors)
        end

        post :update_profile
        assigns[:error_msg].grep("バリデーションエラーです").size.should == 2
      end
      it "一つだけプロフィールにエラーが設定されている場合、１つのバリデーションエラーのみが設定されること" do
        errors = mock('errors', :full_messages => ["バリデーションエラーです"])
        @profiles.last.stub!(:valid?).and_return(false)
        @profiles.last.stub!(:errors).and_return(errors)

        post :update_profile
        assigns[:error_msg].grep("バリデーションエラーです").size.should == 1
      end
      it "プロフィールにエラーが無い場合、バリデーションエラーが設定されていないこと" do
        post :update_profile
        assigns[:error_msg].should == assigns[:user].errors.full_messages
      end
    end
  end

  describe MypageController, "POST #apply_password" do
    before do
      INITIAL_SETTINGS['login_mode'] = 'password'

      @user = user_login
      @user.should_receive(:change_password)
      @user.should_receive(:errors).and_return([])

      post :apply_password
    end
    it { response.should redirect_to(:action => :manage, :menu => :manage_password) }
  end

  describe MypageController, "POST #apply_email" do
    before do
      @user = user_login
      ActionMailer::Base.deliveries.clear
      session[:user_id] = 1
    end
    it "should be successful" do
      post :apply_email, {:applied_email => {:email => SkipFaker.email}}
      response.should be_success
      assigns[:menu].should == "manage_email"
      assigns[:user].should == @user
      AppliedEmail.find_by_id(assigns(:applied_email).id).should_not be_nil
      ActionMailer::Base.deliveries.first.body.should match(/http:\/\/test\.host\/mypage\/update_email\/.*/m)
    end
  end

  describe MypageController, "POST #apply_ident_url" do
    before do
      @user = user_login
      ActionMailer::Base.deliveries.clear
      INITIAL_SETTINGS['login_mode'] = 'rp'
      INITIAL_SETTINGS['fixed_op_url'] = nil
      @openid_url = "http://id.example.com/a_user"
    end
    describe '認証を開始した場合' do
      before do
        @result = mock('result')
        controller.should_receive(:authenticate_with_open_id).and_yield(@result, @openid_url)
      end
      describe "認証が成功した場合" do
        before do
          @result.stub!(:successful?).and_return(true)
          @identifier = mock_model(OpenidIdentifier, 'url=' => "", :url => "url" )
          @identifier.stub!(:url=)
          @user.stub!(:openid_identifiers).and_return([@identifier])
        end
        describe "保存に成功する場合" do
          before do
            @identifier.should_receive(:save).and_return(true)
            get :apply_ident_url, :openid_url => @openid_url
          end
          it "リダイレクトされること" do
            response.should redirect_to(:action => :manage, :menu => :manage_openid)
          end
        end
        describe "保存に失敗する場合" do
          before do
            @identifier.should_receive(:save).and_return(false)
            get :apply_ident_url, :openid_url => @openid_url
          end
          it "openidの設定画面がrenderされること" do
            response.should render_template('manage_openid')
          end
        end
      end
      describe "認証が失敗した場合" do
        before do
          @result.stub!(:successful?).and_return(false)
          get :apply_ident_url, :openid_url => @openid_url
        end
        it "flashにエラーが設定されていること" do
          flash[:error].should == "OpenIDの処理の中でキャンセルされたか、失敗しました。"
        end
        it "openidの設定画面がrenderされること" do
          response.should render_template('manage_openid')
        end
      end
    end
    describe 'openidのパラメータが無い場合' do
      before do
        get :apply_ident_url
      end
      it "flashにエラーが設定されていること" do
        flash[:error].should == "OpenIDを入力してください。"
      end
      it "openidの設定画面がrenderされること" do
        response.should render_template('manage_openid')
      end
    end
  end
end

describe MypageController, 'アンテナの整備関連' do
  describe MypageController, "GET #antenna_list" do
    before do
      user_login
      @result_text = 'result_text'
      controller.should_receive(:current_user_antennas_as_json).and_return(@result_text)
      get :antenna_list
    end
    it { response.should include_text(@result_text) }
  end
end

#privateメソッドのspec
describe MypageController, '#setup_for_antenna_box' do
  before do
    @controller = MypageController.new
    @controller.stub!(:find_system_antennas)
    @controller.stub!(:find_antennas)
    @controller.stub!(:current_user).and_return(stub_model(User))
    @controller.stub!(:login_user_symbols)
    @controller.stub!(:login_user_groups)
    Antenna.stub!(:get_system_antennas)
  end
  it '@system_antennasが設定されること' do
    mock_system_antennas = mock('system_antennas')
    Antenna.should_receive(:get_system_antennas).and_return(mock_system_antennas)
    @controller.send!(:setup_for_antenna_box)
    @controller.instance_eval{ @system_antennas.should == mock_system_antennas }
  end
  it '@my_antennasが設定されること' do
    mock_my_antennas = mock('my_antennas')
    @controller.should_receive(:find_antennas).and_return(mock_my_antennas)
    @controller.send!(:setup_for_antenna_box)
    @controller.instance_eval{ @my_antennas.should == mock_my_antennas }
  end
end

describe MypageController, '#parse_date' do
  before do
    @controller = MypageController.new
    @controller.stub!(:params).and_return({:year => '2009', :month => '1', :day => '2'})
  end
  it 'year, month, dayが返却されること' do
    @controller.send!(:parse_date).should == [2009, 1, 2]
  end
end

describe MypageController, '#system_messages' do
  before do
    @controller = MypageController.new
    @user = stub_model(User, :pictures => [])
    @controller.stub!(:current_user).and_return(@user)
  end
  describe 'ようこそメッセージを表示する場合' do
    it { @controller.send!(:system_messages, {:show_welcome_message => true}).size.should == 2 }
  end
  describe 'ようこそメッセージを表示しない場合' do
    it { @controller.send!(:system_messages, {:show_welcome_message => false}).size.should == 1 }
  end
end

describe MypageController, "#unify_feed_form" do
  before do
    @channel = mock('channel')
    @items = (1..5).map{|i| mock("item#{i}") }
    @feed = mock('feed', :channel => @channel, :items => @items)

    @title = "title"
    @limit = 1
  end

  # 1.8.6系で実行できないためAtomを利用できるバージョンでのみテストする
  if defined?(RSS::Atom::Feed)
    describe "feedがRSS:Rssの場合" do
      before do
        @channel.stub!(:title=)
        @feed.stub!(:is_a?).with(RSS::Rss).and_return(true)
      end
      it "titleが設定されること" do
        @channel.should_receive(:title=).with(@title)
        controller.send(:unify_feed_form, @feed, @title)
      end
      it "limit以下のアイテム数になること" do
        feed = controller.send(:unify_feed_form, @feed, @title, @limit)
        feed.items.size.should == @limit
      end
      it "is_a?(RSS::Atom::Feed)が呼ばれないこと" do
        @feed.should_not_receive(:is_a?).with(RSS::Atom::Feed)
        controller.send(:unify_feed_form, @feed, @title)
      end
    end
    describe "feedがRSS::Atomの場合" do
      describe "Atomが利用できるライブラリのバージョンの場合" do
        before do
          @channel.stub!(:title=)

          @feed.stub!(:is_a?).with(RSS::Rss).and_return(false)
          @feed.stub!(:is_a?).with(RSS::Atom::Feed).and_return(true)
          @feed.stub!(:to_rss).with("2.0").and_return(@feed)
        end
        it "AtomからRss2.0に変換されること" do
          @feed.should_receive(:to_rss).with("2.0").and_return(@feed)
          controller.send(:unify_feed_form, @feed)
        end
        it "titleが設定されること" do
          @channel.should_receive(:title=).with(@title)
          controller.send(:unify_feed_form, @feed, @title, @limit)
        end
        it "limit以下のアイテム数になること" do
          feed = controller.send(:unify_feed_form, @feed, @title, @limit)
          feed.items.size.should == @limit
        end
      end
    end
    describe "Atomが利用できないライブラリのバージョンでAtomを読み込んだ場合" do
      before do
        @feed.stub!(:is_a?).with(RSS::Rss).and_return(false)
        @feed.stub!(:is_a?).with(RSS::Atom::Feed).and_raise(NameError.new("uninitialized constant RSS::Atom", "RSS::Atom::Feed"))
      end
      it "ログにエラーが表示されること" do
        controller.logger.should_receive(:error).with("[Error] Rubyのライブラリが古いためAtom形式を変換できませんでした。")
        controller.send(:unify_feed_form, @feed)
      end
      it "nilが返されること" do
        controller.send(:unify_feed_form, @feed).should be_nil
      end
    end
  end
end

describe MypageController, '#valid_list_types' do
  before do
    @controller = MypageController.new
    GroupCategory.should_receive(:all).and_return([stub_model(GroupCategory, :code => 'category')])
  end
  it { @controller.send!(:valid_list_types).should == %w(questions access_blogs recent_blogs category) }
end

describe MypageController, '#antenna_entry_title' do
  before do
    @controller = MypageController.new
  end
  describe '引数が正しい場合' do
    describe 'アンテナが指定されている場合' do
      before do
        @antenna_entry = stub('antenna_entry', :antenna => stub_model(Antenna, :name => 'skip_antenna'))
      end
      it { @controller.send(:antenna_entry_title, @antenna_entry).should == 'skip_antenna' }
    end
    describe 'アンテナが指定されていない場合' do
      describe 'システムアンテナの場合' do
        it { @controller.send!(:antenna_entry_title, stub('entry_antenna', :antenna => nil, :key => 'message')).should == 'あなたへ宛てた連絡' }
        it { @controller.send!(:antenna_entry_title, stub('entry_antenna', :antenna => nil, :key => 'comment')).should == '過去にあなたがコメントを残した記事'}
        it { @controller.send!(:antenna_entry_title, stub('entry_antenna', :antenna => nil, :key => 'bookmark')).should == 'あなたがブックマークした記事' }
        it { @controller.send!(:antenna_entry_title, stub('entry_antenna', :antenna => nil, :key => 'group')).should == '参加中のグループの掲示版の書き込み' }
      end
      describe 'システムアンテナではない場合' do
        it { @controller.send!(:antenna_entry_title, stub('entry_antenna', :antenna => nil, :key => nil)).should == '未読記事の一覧' }
        it { @controller.send!(:antenna_entry_title, stub('entry_antenna', :antenna => nil, :key => 'invalid')).should == '未読記事の一覧' }
      end
    end
  end
end

describe MypageController, '#unread_entry_id_hash_with_user_reading' do
  before do
    @controller = MypageController.new
    @controller.stub!(:current_user).and_return(stub_model(User))
  end
  describe '指定された記事idがnilの場合' do
    it '空ハッシュが返ること' do
      @controller.send!(:unread_entry_id_hash_with_user_reading, nil).should == {}
    end
  end
  describe '指定された記事idの配列サイズが0の場合' do
    it '空ハッシュが返ること' do
      @controller.send!(:unread_entry_id_hash_with_user_reading, []).should == {}
    end
  end
  describe '指定された記事idの配列サイズが1以上の場合' do
    describe '対象のUserReadingが存在する場合' do
      before do
        @read_user_reading = stub_model(UserReading, :board_entry_id => 77, :read => true)
        @unread_user_reading = stub_model(UserReading, :board_entry_id => 777, :read => false)
        @user_readings = [@read_user_reading, @unread_user_reading]
        UserReading.should_receive(:find).and_return(@user_readings)
      end
      it '記事のidをキーとして未読のUserReadingのハッシュが返ること' do
        @expected = { 777 => @unread_user_reading }
        @controller.send!(:unread_entry_id_hash_with_user_reading, [77, 777]).should == @expected
      end
    end
    describe '対象のUserReadingが存在しない場合' do
      before do
        UserReading.should_receive(:find).and_return([])
      end
      it '空ハッシュが返ること' do
        @controller.send!(:unread_entry_id_hash_with_user_reading, [77, 777]).should == {}
      end
    end
  end
end
