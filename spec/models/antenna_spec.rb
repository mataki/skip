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
class AntennaTest < Test::Unit::TestCase
  fixtures :antennas, :antenna_items, :board_entries, :entry_publications, :user_readings, :users

  def test_get_search_conditions
    #symbolでアンテナが登録されている場合
    guchon_symbols, empty_keyword = @a_symbol_antenna.get_search_conditions
    assert_equal guchon_symbols.first, "uid:a_user"
    assert_equal empty_keyword, ""
    #keywordでアンテナが登録されている場合
    empty_symbols, java_keyword = @a_keyword_antenna.get_search_conditions
    assert_equal empty_symbols, []
    assert_equal java_keyword, "java"
  end

#  def test_find_with_counts
#    antennas_for_maeda = Antenna.find_with_counts('6', [])
#    assert_equal antennas_for_maeda.length, 2
#    assert_equal antennas_for_maeda[0].count, 1
#    assert_equal antennas_for_maeda[1].count, 0
#  end

end
