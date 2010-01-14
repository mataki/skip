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

describe UsersController do
  describe "route generation" do
    it "should map #show" do
      route_for(:controller => "ids", :action => "show", :user => "1").should == "/id/1"
    end
    it "should map #show" do
      route_for(:controller => "ids", :action => "show", :user => "").should == "/id/"
    end
  end

  describe "route recognition" do
    it "should generate params for #show" do
      params_from(:get, "/id/1").should == {:controller => "ids", :action => "show", :user => "1"}
    end
  end
end
