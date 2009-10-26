require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Page do
  describe "ページの初期設定時" do
    #TODO have_at_leastが期待通りの動きをしない
    it "ページは必ず1件以上存在すること" do
      (Page.all.size >= 1).should be_true
    end
  end
end
