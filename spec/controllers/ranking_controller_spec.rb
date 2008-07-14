require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RankingController,"POST update" do
  before do
    user_login
  end
  describe "既にその日の分のランキングが存在する場合" do
    before do
        r = Ranking.new
        Ranking.should_receive(:new).at_least(:once).and_return(r) 
    end
    describe "保存できた場合" do
      before do
        ran = Ranking.new
        ran.should_receive(:add_amount).and_return(true)
        Ranking.should_receive(:find_by_url_and_extracted_on_and_contents_type_id).and_return([ran])

        post :update
      end
     it "件数が更新されたので、ステータスコードを返す" do 
       response.code.should == '200'
      end
    end
    describe "保存できなかった場合" do
      before do
        ran = Ranking.new
        ran.should_receive(:add_amount).and_return(false)
        Ranking.should_receive(:find_by_url_and_extracted_on_and_contents_type_id).and_return([ran])

        post :update
      end
      it "件数が加算されなかったので、ステータスコードを返す" do
        response.code.should == '400'
      end
    end
  end
  describe "その日の分のランキングが存在しない場合" do
    before do
      Ranking.should_receive(:find_by_url_and_extracted_on_and_contents_type_id).and_return([])
    end
    describe "保存できた場合" do
      before do
        r = Ranking.new
        r.should_receive(:save).and_return(true)
        Ranking.should_receive(:new).and_return(r) 
        post :update
      end
      it "リソースが作られたので、ステータスコード201を返す" do
       response.code.should == '201'
      end
    end
    describe "保存できなかった場合" do
      before do
        r = Ranking.new
        r.should_receive(:save).and_return(false)
        Ranking.should_receive(:new).and_return(r) 
        post :update
      end
      it "リソースが作られなかったので、ステータスコード400を返す" do
       response.code.should == '400'
      end
    end
  end
end

describe RankingController, 'GET /rankings/:content_type/:year/:month' do
  before do
    user_login
  end
  describe 'content_typeの指定が不正(nil又は空)の場合' do
    before  { get :index, :content_type => '' }
    it 'bad_requestを返すこと' do
      response.code.should == '400'
    end
  end

  describe 'content_typeが正しい場合' do
    describe 'yearが不正な場合' do
      it 'bad_requestを返すこと'
    end
    describe 'yearが正しい場合' do
      describe 'monthが指定されていない場合' do
        it 'bad_requestを返すこと'
      end
      describe 'monthが不正な場合' do
        it 'bad_requestを返すこと'
      end
    end
  end

  describe '統合ランキングが検索されてデータが見つかる時' do
    before do
      @rankings = (1..10).map{|i| mock_model(Ranking)}
      Ranking.should_receive(:all_rankings).with(anything).and_return(@rankings)
      get :index, :content_type => 'entry_access'
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

  describe '統合ランキングが検索されてデータが見つからない時' do
    it '404を返すこと'
  end

  describe '月間ランキングが検索されてデータが見つかる時' do
    before do
      @rankings = (1..10).map{|i| mock_model(Ranking)}
      Ranking.should_receive(:monthry_rankings).with(anything, anything, anything).and_return(@rankings)
      get :index, :content_type => 'entry_access', :year => '2008', :month => '8'
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
  end

  describe '月間ランキングが検索されてデータが見つからない時' do
    it '404を返すこと'
  end
end
