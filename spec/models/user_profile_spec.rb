# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008  TIS Inc.
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

describe UserProfile do
  before(:each) do
    @user_profile = UserProfile.new(:user_id=>"1",:alma_mater=>"shussinkou",:address_2=>"address02")
  end

  it "too long alma_mater is NG" do
    @user_profile.alma_mater = "abcdefghijklmnopqrstu"
    @user_profile.should_not be_valid
  end

  it "too long address_2 is NG" do
    @user_profile.address_2 = "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvw"
    @user_profile.should_not be_valid
  end

  it "longest alma_mater is OK" do
    @user_profile.alma_mater = "abcdefghijklmnopqrs"
    @user_profile.should be_valid
  end

  it "longest address_2 is OK" do
    @user_profile.address_2 = "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuv"
    @user_profile.should be_valid
  end
end
