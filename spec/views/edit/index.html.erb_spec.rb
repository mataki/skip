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

require File.dirname(__FILE__) + '/../../spec_helper'

describe "/edit/index" do
  fixtures :board_entries, :users
  before(:each) do
    @categories_hash = {:mine=>[], :system=>[], :user=>[], :standard=>[]}
    @place = "a_userのブログ"
    @target_url_param = {:action=>"blog", :uid=>"a_user", :archive=>"all", :controller=>"user"}

    assigns[:categories_hash] = @categories_hash
    assigns[:place] = @place
    assigns[:target_url_param] = @target_url_param

    @board_entry = assigns[:board_entry] = board_entries(:a_entry)

    render 'edit/index'
  end

  it "should tell you where to find the file" do
    response.should have_tag('div.input_value', /a_userのブログ/)
  end
end
