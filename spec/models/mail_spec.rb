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

describe Mail do
  before do
    @mail = new_mail :to_address_symbol => "uid:hoge"
  end
  it { @mail.save.should be_true }
  it { @mail.symbol_type.should == 'uid' }
  it { @mail.symbol_id.should == 'hoge' }
end

def new_mail(options = {})
  Mail.new({ :to_address_name => 'uid:hoge', :user_entry_no => "1"}.update(options))
end
