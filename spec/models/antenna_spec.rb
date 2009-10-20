# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
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
  fixtures :users
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
    antennas = Antenna.find_with_counts(@a_user)
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

describe Antenna, ".create_initial" do
  before do
    @user = stub_model(User)
  end
  describe "アンテナ名とアンテナグループが設定されている場合" do
    before do
      @initial_antenna = "初期アンテナ名"
      SkipEmbedded::InitialSettings.stub!("[]").with('initial_antenna').and_return(@initial_antenna)
      SkipEmbedded::InitialSettings.stub!("[]").with('antenna_default_group').and_return(['vimgroup', 'emacsgroup'])
    end
    describe "存在するグループが複数(2)設定されている場合" do
      before do
        create_group :gid => 'vimgroup'
        create_group :gid => 'emacsgroup'
        @antenna = Antenna.create_initial(@user)
      end
      it "アンテナに複数(2)アイテムが登録されていること" do
        @antenna.antenna_items.length.should == 2
      end
      it "アンテナ名が登録されていること" do
        @antenna.name.should == @initial_antenna
      end
    end
    describe "存在しないグループが含まれている場合" do
      before do
        create_group :gid => 'vimgroup'
        create_group :gid => 'emacsgroup', :deleted_at => Time.now
        @antenna = Antenna.create_initial(@user)
      end
      it "アンテナに存在するグループのアイテムが登録されていること" do
        @antenna.antenna_items.length.should == 1
      end
      it "アンテナ名が登録されていること" do
        @antenna.name.should == @initial_antenna
      end
    end
  end
  describe "アンテナ名が設定されていない場合" do
    before do
      SkipEmbedded::InitialSettings.stub!("[]").with('initial_antenna').and_return(nil)
      SkipEmbedded::InitialSettings.stub!("[]").with('antenna_default_group').and_return(['vimgroup', 'emacsgroup'])
    end
    it "nilが返ること" do
      Antenna.create_initial(@user).should be_nil
    end
  end
  describe "アンテナグループが設定されていない場合" do
    before do
      SkipEmbedded::InitialSettings.stub!("[]").with('initial_antenna').and_return("初期アンテナ名")
      SkipEmbedded::InitialSettings.stub!("[]").with('antenna_default_group').and_return(nil)
    end
    it "nilが返ること" do
      Antenna.create_initial(@user).should be_nil
    end
  end
end


