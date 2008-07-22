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
