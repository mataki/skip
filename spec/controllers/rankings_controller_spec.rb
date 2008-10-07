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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# TODO 外部からのランキング取り込み機能は一旦ペンディングなのでコメントアウト
#describe RankingsController,"POST update" do
#  before do
#    user_login
#  end
#  describe "既にその日の分のランキングが存在する場合" do
#    before do
#        r = Ranking.new
#        Ranking.should_receive(:new).at_least(:once).and_return(r) 
#    end
#    describe "保存できた場合" do
#      before do
#        ran = Ranking.new
#        ran.should_receive(:add_amount).and_return(true)
#        Ranking.should_receive(:find_by_url_and_extracted_on_and_contents_type).and_return([ran])
#
#        post :update
#      end
#     it "件数が更新されたので、ステータスコードを返す" do 
#       response.code.should == '200'
#      end
#    end
#    describe "保存できなかった場合" do
#      before do
#        ran = Ranking.new
#        ran.should_receive(:add_amount).and_return(false)
#        Ranking.should_receive(:find_by_url_and_extracted_on_and_contents_type).and_return([ran])
#
#        post :update
#      end
#      it "件数が加算されなかったので、ステータスコードを返す" do
#        response.code.should == '400'
#      end
#    end
#  end
#  describe "その日の分のランキングが存在しない場合" do
#    before do
#      Ranking.should_receive(:find_by_url_and_extracted_on_and_contents_type).and_return([])
#    end
#    describe "保存できた場合" do
#      before do
#        r = Ranking.new
#        r.should_receive(:save).and_return(true)
#        Ranking.should_receive(:new).and_return(r) 
#        post :update
#      end
#      it "リソースが作られたので、ステータスコード201を返す" do
#       response.code.should == '201'
#      end
#    end
#    describe "保存できなかった場合" do
#      before do
#        r = Ranking.new
#        r.should_receive(:save).and_return(false)
#        Ranking.should_receive(:new).and_return(r) 
#        post :update
#      end
#      it "リソースが作られなかったので、ステータスコード400を返す" do
#       response.code.should == '400'
#      end
#    end
#  end
#end

describe RankingsController, '#index' do
  before do
    user_login
    @year, @month = 2008, 7
    Date.should_receive(:today).and_return(Date.new(@year, @month))
    get :index
  end
  it '今月のランキングにリダイレクトされること' do
    response.should redirect_to("/rankings/monthly/#{@year}/#{@month}")
  end
end

describe RankingsController, 'GET /ranking_data/:content_type/:year/:month' do
  before do
    user_login
  end
  describe 'content_typeの指定が不正(nil又は空)の場合' do
    before  { get :data, :content_type => '' }
    it 'bad_requestを返すこと' do
      response.code.should == '400'
    end
  end

  # パラメタが不正な場合のテスト
  describe 'content_typeが正しい場合' do
    before { @content_type = 'entry_access' }
    describe 'yearの指定がある場合' do
      describe 'monthが指定されていない場合' do
        before { get :data, :content_type => @content_type, :year => '2008' }
        it 'bad_requestを返すこと' do
          response.code.should == '400'
        end
      end

      describe 'monthが指定されている場合' do
        describe 'yearが不正な場合' do
          before { get :data, :content_type => @content_type, :year => '1000', :month => '8' }
          it 'bad_requestを返すこと' do
            response.code.should == '400'
          end
        end
        describe 'monthが不正な場合' do
          before { get :data, :content_type => @content_type, :year => '2008', :month => '13' }
          it 'bad_requestを返すこと' do
            response.code.should == '400'
          end
        end
      end
    end
  end

  describe '統合ランキングが検索される場合' do
    describe 'データが見つかる場合' do
      before do
        @rankings = (1..10).map{|i| mock_model(Ranking)}
        Ranking.should_receive(:total).with(anything).and_return(@rankings)
        get :data, :content_type => 'entry_access'
      end
      it 'content_typeがparamに含まれること' do
        params[:content_type].should_not be_nil
      end
      it 'yearがparamに含まれていないこと' do
        params[:year].should be_nil
      end
      it '@rankingsにデータが設定されていること' do
        assigns[:rankings].should == @rankings
      end
      it '200を返すこと' do
        response.should be_success
      end
    end
    describe 'データが見つからない場合' do
      before do
        @rankings = []
        Ranking.should_receive(:total).with(anything).and_return(@rankings)
        get :data, :content_type => 'entry_access'
      end
      it '404を返すこと' do
        response.code.should == '404'
      end
    end
  end

  describe '月間ランキングが検索される場合' do
    describe 'データが見つかる場合' do
      before do
        @rankings = (1..10).map{|i| mock_model(Ranking)}
        Ranking.should_receive(:monthly).with(anything, anything, anything).and_return(@rankings)
        get :data, :content_type => 'entry_access', :year => '2008', :month => '8'
      end
      it 'content_typeがparamに含まれること' do
        params[:content_type].should_not be_nil
      end
      it 'yearがparamに含まれること' do
        params[:year].should_not be_nil
      end
      it 'monthがparamに含まれること' do
        params[:month].should_not be_nil
      end
      it '@rankingsにデータが設定されていること' do
        assigns[:rankings].should == @rankings
      end
      it '200を返すこと' do
        response.should be_success
      end
    end
    describe 'データが見つからない場合' do
      before do
        @rankings = []
        Ranking.should_receive(:monthly).with(anything, anything, anything).and_return(@rankings)
        get :data, :content_type => 'entry_access', :year => '2008', :month => '8'
      end
      it '404を返すこと' do
        response.code.should == '404'
      end
    end
  end
end

describe RankingsController, '#all' do
  before do
    user_login
    get :all
  end
  it { response.should be_success }
end

describe RankingsController, '#monthly' do
  before do
    user_login
  end
  describe '年月の指定が無い場合' do
    before do
      @today = Date.today
      get :monthly
    end
    it { assigns[:year].should == @today.year }
    it { assigns[:month].should == @today.month }
    it { response.should be_success }
  end

  describe '年月の指定がある場合' do
    before do
      @year = '2008'
      @month = '8'
      get :monthly, :year => @year, :month => @month
    end
    it { assigns[:year].should == @year.to_i }
    it { assigns[:month].should == @month.to_i }
    it { response.should be_success }
  end

  describe '年のみ指定がある場合' do
    before do
      @year = '2008'
      @month = Date.today.month
      get :monthly, :year => @year
    end
    it { assigns[:year].should == @year.to_i }
    it { assigns[:month].should == @month.to_i }
    it { response.should be_success }
  end

  describe '不正なパラメタが指定された場合' do
    before do
      @year = '123456'
      get :monthly, :year => @year
    end
    it { response.code.should == '400' }
  end
end

describe RankingsController, "GET #statistics" do
  before do
    user_login

    @date = mock('date')

    @item_count = mock('item_count')
    controller.stub!(:get_site_count_hash_by_day).and_return(@item_count)
  end
  it "カレンダー表示用のHashが@item_countに設定されていること" do
    get :statistics
    assigns[:item_count].should == @item_count
  end

  describe "年月日のデータが渡された場合" do
    def get_statistics_with_date
      get :statistics, :year => "2008", :month => "10", :day => "3"
    end
    before do
      @date = mock('date')
      Date.stub!(:new).with(2008, 10, 3).and_return(@date)

      SiteCount.stub!(:get_by_date).and_return(nil)
    end
    it "@dateにパラメータから渡された年月日が入っていること" do
      get_statistics_with_date
      assigns[:date].should == @date
    end
    describe "データが見つかる場合" do
      before do
        @site_count = stub_model(SiteCount)
        SiteCount.should_receive(:get_by_date).with(@date).and_return(@site_count)

        get_statistics_with_date
      end
      it "statisticsがrenderされること" do
        response.should render_template('statistics')
      end
      it "該当するSiteCountが@site_countに設定されていること" do
        assigns[:site_count].should == @site_count
      end
    end
    describe "データが見つからない場合" do
      before do
        SiteCount.should_receive(:get_by_date).with(@date).and_return(nil)

        get_statistics_with_date
      end
      it "statisticsがrenderされること" do
        response.should render_template('statistics')
      end
      it "新規のSiteCountが@site_countに設定されていること" do
        assigns[:site_count].should be_new_record
      end
      it "flashにメッセージが設定されていること" do
        flash[:notice].should == '対象データが見つかりません。'
      end
    end
  end
  describe "パラメータが与えられない場合" do
    it "@dateにDate.todayが入っていること" do
      get :statistics
      assigns[:date].should == Date.today
    end
    describe "データが見つかる場合" do
      before do
        @site_count = stub_model(SiteCount)
        # applicationコントローラーで呼ばれるので２回になる
        SiteCount.should_receive(:find).twice.with(:first, :order => "created_on desc").and_return(@site_count)

        get :statistics
      end
      it "statisticsがrenderされること" do
        response.should render_template('statistics')
      end
      it "該当のSiteCountが@site_countに設定されていること" do
        assigns[:site_count].should == @site_count
      end
    end
    describe "データが見つからない場合" do
      before do
        SiteCount.should_receive(:find).twice.with(:first, :order => "created_on desc").and_return(nil)

        get :statistics
      end
      it "statisticsがrenderされること" do
        response.should render_template('statistics')
      end
      it "新規のSiteCountが@site_countに設定されていること" do
        assigns[:site_count].should be_new_record
      end
      it "flashにメッセージが設定されていること" do
        flash[:notice].should == '対象データが見つかりません。'
      end
    end
  end
end
