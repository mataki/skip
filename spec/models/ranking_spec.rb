require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User, 'named_scope' do
  describe '.by_contents_type' do
    before do
      %w(entry_access comment).each do |s|
        create_ranking(:contents_type => s)
      end
    end
    it '指定したcontents_typeのデータが取得できること' do
      Ranking.by_contents_type(:entry_access).should have(1).items
    end
  end

  describe '.max_amount_by_url' do
    before do
      create_ranking(:contents_type => 'entry_access', :extracted_on => Date.yesterday, :amount => 1)
      create_ranking(:contents_type => 'entry_access', :extracted_on => Date.today, :amount => 2)
      create_ranking(:contents_type => 'entry_access', :extracted_on => Date.tomorrow, :amount => 3)
    end
    it 'urlでグルーピングされていること' do
      Ranking.max_amount_by_url.should have(1).items
    end
    it 'extracted_onが最大のレコードのamountの値になること' do
      pending 'maxしたレコードのほかのカラムの取り方不明'
      #Ranking.max_amount_by_url.first.amount.should == 3
    end
  end
end
