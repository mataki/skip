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

describe UserUid do
  before(:each) do
    @user_uid = UserUid.new
  end
end

describe User,"'s class methods" do
  fixtures :users
  before(:each) do
    @user = users(:a_user)
  end

  it "check_uid" do
    UserUid.check_uid("101010", "101010").should == "登録可能です"
    UserUid.check_uid("101010", "101011").should_not == "登録可能です"
    UserUid.check_uid(SkipFaker.rand_char(3), "101011").should_not == "登録可能です"
    UserUid.check_uid(SkipFaker.rand_char(32), "101011").should_not == "登録可能です"
    UserUid.check_uid("_abc", "101010").should == "登録可能です"
    UserUid.check_uid("+abc", "101010").should_not == "登録可能です"
    UserUid.check_uid(@user.uid,"101010").should_not == "登録可能です"
  end
end
