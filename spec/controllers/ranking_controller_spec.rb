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
