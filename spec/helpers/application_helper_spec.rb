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

describe ApplicationHelper, "#show_contents" do
  describe "hikiモードの時" do
    before do
      @entry = stub_model(BoardEntry, :editor_mode => 'hiki', :contents => "hogehoge",
                          :symbol => "ほげ", :user_id => 1)
      @output_contents = "output_contents {{question.gif,240,}} output_contents"
      helper.stub!(:hiki_parse).and_return(@output_contents)

      @result = helper.show_contents(@entry)
    end
    it { @result.should have_tag("div.hiki_style") }
    it { @result.should be_include('output_contents') }
    it { @result.should be_include("/images/board_entries/#{@entry.user_id}/#{@entry.id}_question.gif") }
  end
end
