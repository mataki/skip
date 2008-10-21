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

describe BatchMakeCache, "#create_meta" do
  before do
    bmc = BatchMakeCache.new
    params = { :title => "title",
      :contents_type => "page",
      :publication_symbols => "sid:allusers",
      :link_url => "/user/hoge",
      :icon_type => "icon"
    }
    @result = bmc.create_meta(params)
  end
  it "link_urlが正しく設定されること" do
    @result.should be_include("link_url: #{INITIAL_SETTINGS['protocol']}#{INITIAL_SETTINGS['host']}/user/hoge")
  end
end
