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

describe User, "do not have attributes" do
  before(:each) do
    @user = User.new
  end

  it "should be valid" do
    @user.should_not be_valid
  end

  it "set errors to email" do
    @user.should have(2).errors_on(:email)
  end

  it "set errors to name" do
    @user.should have(1).errors_on(:name)
  end

  it "set errors to extention" do
    @user.should have(3).errors_on(:extension)
  end

  it "set errors to introduction" do
    @user.should have(1).errors_on(:introduction)
  end
end

describe User," is a_user" do
  fixtures :users, :user_accesses, :user_uids
  before(:each) do
    @user = users(:a_user)
  end

  it "get uid and name by to_s" do
    @user.to_s.should == "uid:#{@user.uid}, name:#{@user.name}"
  end

  it "get symbol_id" do
    @user.symbol_id.should == "a_user"
  end

  it "get symbol" do
    @user.symbol.should == "uid:a_user"
  end

  it "get before_access" do
    @user.before_access.should == "1 日以内"
  end

  it "set mark_track" do
    lambda {
      @user.mark_track(users(:a_group_joined_user).id)
    }.should change(Track, :count).by(1)
  end
end
