require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Ranking, '#add_amount' do
  before do
    @ranking = create_ranking
  end
  describe '引数が正しい場合' do
    it '引数の数がranking#amountに加算されていること' do
      lambda do
        @ranking.add_amount(1)
        @ranking.reload
      end.should change(@ranking, :amount).from(1).to(2)
    end
    it '処理に成功したらtrueを返すこと' do
      @ranking.add_amount(1).should be_true
    end
    it '処理に失敗したらfalseを返すこと' do
      @ranking.should_receive(:save).and_return(false)
      @ranking.add_amount(1).should be_false
    end
  end

  describe '引数が不正な場合' do
    it '引数が数値以外ならfalseを返すこと' do
      @ranking.add_amount('hoge').should be_false
    end

    it '引数が正の整数以外ならfalseを返すこと' do
      @ranking.add_amount(-1).should be_false
    end

    it '引数が0のならfalseを返すこと' do
      @ranking.add_amount(0).should be_false
    end
  end

#  before(:each) do
#    @ranking = Ranking.new
#  end
#
#  it "should be valid" do
#    @ranking.should be_valid
#  end
end
