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

# describe HyperEstraier do
#   def test_truep
#     assert true
#   end

#   def test_search
#     params = { }
#     params[:full_text_query] = "中井"
#     result_hash = {
#       :header => { :count => -1, :start_count => 0, :end_count => 0, :prev => "", :next => "", :per_page => 10 },
#       :elements => []
#     }
#     result = HyperEstraier.search params,result_hash

#     assert result[:error].blank?
#     assert_equal(result[:header][:count].to_i,42)
#   end

#   def test_search_by_uri
#     params = { }
#     params[:full_text_query] = '中井'
#     params[:target_aid] = 'skip'
#     params[:target_contents] = 'user'
#     result_hash = {
#       :header => { :count => -1, :start_count => 0, :end_count => 0, :prev => "", :next => "", :per_page => 10 },
#       :elements => []
#     }
#     result = HyperEstraier.search params,result_hash

#     assert result[:error].blank?
#     assert_equal(result[:header][:count].to_i,2)
#   end

#   def test_search_next
#     params = { }
#     params[:full_text_query] = "中井"
#     params[:offset] = 40
#     result_hash = {
#       :header => { :count => -1, :start_count => 0, :end_count => 0, :prev => "", :next => "", :per_page => 10 },
#       :elements => []
#     }
#     result = HyperEstraier.search params,result_hash

#     assert result[:error].blank?
#     assert_equal(result[:header][:count].to_i,42)
#     assert_equal(result[:elements].size,2)
#   end

# end
