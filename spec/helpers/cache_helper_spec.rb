# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2010 TIS Inc.
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

describe CacheHelper, "#all_javascript_include_tag" do
  describe "prototypeが引数の場合" do
    before do
      @result = helper.all_javascript_include_tag "prototype"
    end
    CacheHelper::PROTOTYPE_LIBRARY[:libs].each do |lib|
      it { @result.should be_include(lib) }
    end
  end
end

describe CacheHelper, "#all_stylesheet_link_tag" do
  before do
    @result = helper.all_stylesheet_link_tag "style"
  end
  CacheHelper::STYLE_LIBRARY[:libs].each do |lib|
    it { @result.should be_include(lib) }
  end
end
