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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::UserProfile, "#join_year" do
  before do
    @up = Admin::UserProfile.new(:email => "hoge@openskip.org")
  end
  describe "4桁でない場合" do
    before do
      @up.join_year = "11111"
    end
    it { @up.should_not be_valid }
    it { @up.should have(1).errors_on(:join_year) }
  end
  describe "4桁の場合" do
    before do
      @up.join_year = "1111"
    end
    it { @up.should be_valid }
  end
  describe "空の場合" do
    before do
      @up.join_year = nil
    end
    it { @up.should be_valid }
  end
end

describe Admin::UserProfile, "#birth_month" do
  before do
    @up = Admin::UserProfile.new(:email => "hoge@openskip.org")
  end
  describe "正しい月の時" do
    (1..12).each do |i|
      before do
        @up.birth_month = i
      end
      it { @up.should be_valid }
    end
  end
  describe "0の時" do
    before do
      @up.birth_month = 0
    end
    it { @up.should_not be_valid }
  end
  describe "13の時" do
    before do
      @up.birth_month = 13
    end
    it { @up.should_not be_valid }
  end
end
describe Admin::UserProfile, "#birth_day" do
  before do
    @up = Admin::UserProfile.new(:email => "hoge@openskip.org")
  end
  describe "正しい月の時" do
    (1..31).each do |i|
      before do
        @up.birth_day = i
      end
      it { @up.should be_valid }
    end
  end
  describe "0の時" do
    before do
      @up.birth_day = 0
    end
    it { @up.should_not be_valid }
  end
  describe "32の時" do
    before do
      @up.birth_day = 32
    end
    it { @up.should_not be_valid }
  end
end

