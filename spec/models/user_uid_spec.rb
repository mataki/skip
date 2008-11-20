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

describe UserUid, '.validation_error_message' do
  describe 'validなuidの場合' do
    it 'nilを返すこと' do
      UserUid.validation_error_message(SkipFaker.rand_char(4)).should be_nil
    end
  end
  describe 'invalidなuidの場合' do
    it 'エラーメッセージを返すこと' do
      UserUid.validation_error_message(SkipFaker.rand_char(3)).should_not be_nil
    end
  end
end
