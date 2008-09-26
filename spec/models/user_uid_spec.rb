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

describe UserUid, ".check_uid" do
  it "登録できない場合" do
    [SkipFaker.rand_char(3), SkipFaker.rand_char(32), "111111", "11*ff"].each do |uid|
      UserUid.check_uid(uid).should_not == "登録可能です"
    end
  end

  it "登録可能な場合" do
    UserUid.check_uid(SkipFaker.rand_char(10)).should == "登録可能です"
  end
end
