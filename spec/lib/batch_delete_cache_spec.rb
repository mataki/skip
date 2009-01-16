require File.dirname(__FILE__) + '/../spec_helper'

describe BatchDeleteCache, ".execute" do
  it "呼び出せること" do
#    BatchDeleteCache.execute
  end
end

describe BatchDeleteCache::BoardEntryDeleter do
  before do
    @bed = BatchDeleteCache::BoardEntryDeleter.new
  end
  describe "#execute" do
    describe "すべて存在する場合" do
      before do
        @bed.stub!(:all_ids).and_return([1,2,3,4,5])
      end
      it "何も消されないこと" do
        @bed.should_not_receive(:delete_cache)
        @bed.should_not_receive(:delete_meta)

        @bed.execute
      end
    end
    describe "存在しないレコードがある場合" do
      before do
        @bed.stub!(:all_ids).and_return([1,2,4,5])
      end
      it "delete_cacheが呼ばれること" do
        @bed.should_receive(:delete_cache).with(3)
        @bed.execute
      end
      it "delete_metaが呼ばれること" do
        @bed.should_receive(:delete_meta).with(3)
        @bed.execute
      end
    end
  end
  describe "#cache_path" do
    it "キャッシュのpathを返す" do
      @bed.cache_path(3).should == "tmp/app_cache/entry/0000/3.html"
    end
  end
  describe "#meta_path" do
    it "メタのpathを返す" do
      @bed.meta_path(3).should == "tmp/app_cache_meta/entry/0000/3.html"
    end
  end
end

