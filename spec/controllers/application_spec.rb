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

describe ApplicationController, "#sso" do
  describe "SKIPOP設定の場合" do
    before do
      ENV['SKIPOP_URL'] = 'http://localhost.com/'
    end
    describe "未ログイン時" do
      it "ログインへリダイレクトされる" do
        controller.stub!(:logged_in?).and_return(false)
        controller.should_receive(:redirect_to).with({:controller => :platform, :action => :login, :openid_url => ENV['SKIPOP_URL']})
        controller.send(:sso).should be_false
      end
    end

    describe "ログイン時" do
      it "trueを返す" do
        controller.stub!(:logged_in?).and_return(true)
        controller.send(:sso).should be_true
      end
    end
  end
end
