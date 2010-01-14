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

