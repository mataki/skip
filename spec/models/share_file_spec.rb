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

describe ShareFile do
fixtures :share_files
  def test_validate_category
    @a_share_file.category = "[あ=あ][*いえ]"
    assert !@a_share_file.valid?
  end

  def test_owner_symbol_type
    @a_share_file.owner_symbol = 'uid:hoge'
    assert_equal 'user', @a_share_file.owner_symbol_type
    @a_share_file.owner_symbol = 'gid:hoge'
    assert_equal 'group', @a_share_file.owner_symbol_type
  end

  def test_owner_symbol_id
    @a_share_file.owner_symbol = 'uid:hoge'
    assert_equal 'hoge', @a_share_file.owner_symbol_id
  end

  def test_after_save
    @a_share_file.category = SkipFaker.comma_tags :qt => 3
    @a_share_file.save
    assert_equal @a_share_file.share_file_tags.size, 3
  end
end
