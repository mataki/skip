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

describe IdsController, "#show" do
  describe "登録済みのユーザのURLの場合" do
    before do
      User.should_receive(:find_by_code).with("111111").and_return(@user = mock_model(User, :code => "111111"))
    end
    it "ページが表示される" do
      get :show, :user => "111111"
      response.should be_success
    end
    it "ヘッダーに'X-XRDS-Location'が含まれること" do
      get :show, :user => "111111"
      response.headers["X-XRDS-Location"].should == identifier(@user) + "/xrds"
    end
    describe "xrdsフォーマットの場合" do
      it "xrdsを返すこと" do
        get :show, :user => "111111", :format => "xrds"
        response.headers["Content-Type"].should == "application/xrds+xml; charset=utf-8"
      end
      it "show.xrds.builderをレンダリングすること" do
        get :show, :user => "111111", :format => "xrds"
        response.should render_template("show.xrds.builder")
      end
    end
  end
  describe "存在しないユーザのURLの場合" do
    it "ActiveRecord::RecordNotFoundになること" do
      User.should_receive(:find_by_code).and_return(nil)
      lambda do
        get :show, :user => "111111"
      end.should raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
