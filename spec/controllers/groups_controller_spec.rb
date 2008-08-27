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

describe GroupsController do
  before do
    user_login
  end
  describe "#index" do
    describe "グループが存在した場合" do
      before do
        @pages = mock('pages')
        @groups = mock('groups', :size => 1)
        controller.should_receive(:paginate).and_return([@pages, @groups])
        get :index
      end

      it { response.should be_success }
      it { assigns[:format_type].should == "detail" }
      it { assigns[:group_counts].should == Group.count_by_category.first }
      it { assigns[:total_count].should == Group.count_by_category.last}
      it { assigns[:pages].should == @pages }
      it { assigns[:groups].should == @groups }
    end
    describe "グループが存在しなかった場合" do
      before do
        @pages = mock('pages')
        @groups = mock('groups', :size => 0)
        controller.should_receive(:paginate).and_return([@pages, @groups])
        get :index
      end

      it { response.should be_success }
      it { flash[:notice].should_not be_nil }
    end

  end
end
