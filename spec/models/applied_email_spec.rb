# SKIP（Social Knowledge & Innovation Platform）
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

describe AppliedEmail, "に値が設定されていない場合" do
  before(:each) do
    @applied_email = AppliedEmail.new
  end

  it { @applied_email.should_not be_valid }
  it { @applied_email.should have(2).errors_on(:email) }
end

describe AppliedEmail, "に正しい値が設定されている場合" do
  before(:each) do
    @applied_email = AppliedEmail.new({ :email => SkipFaker.email, :user_id => 1 })
  end

  it { @applied_email.should be_valid }

  it "保存時にonetime_codeが設定されていること" do
    @applied_email.save
    @applied_email.onetime_code.should_not be_nil
  end
end
