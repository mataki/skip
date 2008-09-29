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

describe ImageController, "GET #show" do
  before do
    user_login

    controller.should_receive(:valid_params_and_authorize?).and_return(true)
    f = mock('file')
    f.stub!(:read).and_return('read')
    controller.should_receive(:open).with("#{ENV['IMAGE_PATH']}/board_entries/2/2_hoge.jpg", "rb").and_yield(f)
  end
  describe "pathがエンコードされずにわたってきた場合" do
    before do
      get :show, :path => ["board_entries", "2", "2_hoge.jpg"]
    end
    it { response.body.should == "read" }
  end
  describe "pathがエンコードされてわたってきた場合" do
    before do
      get :show, :path => ["board_entries/2/2_hoge.jpg"]
    end
    it { response.body.should == "read" }
  end
end
