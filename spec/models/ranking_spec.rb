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
end
