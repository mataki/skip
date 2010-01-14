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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RankingsHelper, "#ranking_navi_for_month" do
  before do
    @source = ["2009-01", "2009-02", "2009-03"]
  end
  it "表示に[YYYY-MM], valueにURLとなること" do
    helper.ranking_navi_for_month(@source, "2009", "2").should have_tag("option[value=\"#{monthly_path(:year => "2009", :month => "01")}\"]", "2009-01")
  end
  it "月の引数が2の場合、選択されること" do
    helper.ranking_navi_for_month(@source, "2009", "2").should have_tag("option[value=\"#{monthly_path(:year => "2009", :month => "02")}\"][selected]", "2009-02")
  end
  it "月の引数が02の場合、選択されること" do
    helper.ranking_navi_for_month(@source, "2009", "02").should have_tag("option[value=\"#{monthly_path(:year => "2009", :month => "02")}\"][selected]", "2009-02")
  end
end
