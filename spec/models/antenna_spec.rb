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

require File.dirname(__FILE__) + '/../spec_helper'

describe "Antenna#get_search_conditions" do
  before(:each) do
    @antenna = Antenna.new
    @antenna_item1 = mock_model(AntennaItem)
    @antenna_item1.stub!(:value).and_return('uid:a_user')
    @antenna_item1.stub!(:value_type).and_return('symbol')
    @antenna_item2 = mock_model(AntennaItem)
    @antenna_item2.stub!(:value).and_return('ruby')
    @antenna_item2.stub!(:value_type).and_return('keyword')
  end

  describe "symbolでアンテナが登録されている場合" do
    before(:each) do
      @antenna.stub!(:antenna_items).and_return([@antenna_item1])
    end
    it { @antenna.get_search_conditions.first.should be_include('uid:a_user') }
  end

  describe "symbolでアンテナが登録されている場合" do
    before(:each) do
      @antenna.stub!(:antenna_items).and_return([@antenna_item2])
    end
    it { @antenna.get_search_conditions.last.should be_include('ruby') }
  end

  describe "symbolとkeywordがアンテナが登録されている場合" do
    before(:each) do
      @antenna.stub!(:antenna_items).and_return([@antenna_item1,@antenna_item2])
    end
    it { @antenna.get_search_conditions.last.should be_include('ruby') }
    it { @antenna.get_search_conditions.first.should be_include('uid:a_user') }
  end
end

describe "Antenna.find_with_counts" do
  # antennaの条件などを作る部分はAntennaItemに持っていった方がよい
  before(:each) do
    @antenna_item = mock_model(AntennaItem)

    @antenna = Antenna.new
    @antenna.stub!(:antenna_items).and_return([@antenna_item])
    @antenna.stub!(:get_search_conditions)

    Antenna.should_receive(:find).and_return([@antenna])

    BoardEntry.should_receive(:make_conditions).and_return({:conditions => ['']})
    BoardEntry.should_receive(:count).and_return(4)
  end

  it "アンテナごとの未読記事の数を返す" do
    antennas = Antenna.find_with_counts(1, ['uid:a_user'])
    antennas.first.count.should == 4
  end
end

describe "Antenna.find_with_included uid:a_userがアンテナに含まれている場合" do
  before(:each) do
    @antenna_item = mock_model(AntennaItem)
    @antenna_item.stub!(:value_type).and_return('symbol')
    @antenna_item.stub!(:value).and_return('uid:a_user')

    @antenna = Antenna.new
    @antenna.stub!(:antenna_items).and_return([@antenna_item])

    Antenna.should_receive(:find).and_return([@antenna])
  end

  it "引数にuid:a_userを与えるとincludeがtrueになる" do
    antennas = Antenna.find_with_included 1, 'uid:a_user'
    antennas.first.included.should be_true
  end

  it "引数にgid:a_groupを与えるとincludeがfalseになる" do
    antennas = Antenna.find_with_included 1, 'gid:a_group'
    antennas.first.included.should be_false
  end
end

describe "Antenna.get_system_antennas" do
  it "すべてのシステムアンテナをロードする" do
    BoardEntry.stub!(:make_conditions).and_return({ :conditions => ['']})
    BoardEntry.stub!(:count).and_return(1)
    @bookmark = mock_model(Bookmark)
    @bookmark.stub!(:url).and_return('/page/1')
    Bookmark.stub!(:find).and_return([@bookmark])
    @user_reading = mock_model(UserReading)
    @user_reading.stub!(:board_entry_id).and_return(1)
    UserReading.stub!(:find).and_return([@user_reading])

    antennas = Antenna.get_system_antennas(1,['uid:a_user'],['gid:a_group'])
    antenna_types = antennas.map{ |antenna| antenna.antenna_type }
    antenna_types.should be_include('message')
    antenna_types.should be_include('comment')
    antenna_types.should be_include('bookmark')
    antenna_types.should be_include('group')
  end
end
