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

describe Search do
#   def test_hyper_estraier_search
#     params = {}
#     params[:full_text_query] = 'www'
#     search = Search.new params,['sid:allusers']
#     result = search.result

#     assert result[:error].blank?
#     assert_equal(result[:header][:count].to_i,72)
#   end

#   def test_invisible_count
#     params = { :full_text_query => "www"}
#     search = Search.new params,['sid:allusers']
#     invisible_count = search.invisible_count

#     assert_equal invisible_count,1
#   end

  def test_no_query_search
    params = { :full_text_query => "" }
    search = Search.new params,['sid:allusers']

    result = search.result
    assert result[:error].blank?
    assert_equal -1,result[:header][:count].to_i
  end

end
