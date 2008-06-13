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

require File.dirname(__FILE__) + '/../spec_helper'

describe PlatformController do
  before(:all) do
    Session.destroy_all
    @user_info = { "code" => "111111", "name" => SkipFaker.rand_char,
      "email" => SkipFaker.email, "section" => SkipFaker.rand_char }
    @referer = "http://localhost.jp/"
  end

  before(:each) do
    request.env["HTTP_REFERER"] = @referer
  end

  describe "初めてのログインの場合" do
    before(:each) do
      AccountAccess.should_receive(:auth).and_return(@user_info)
      @user = { :key => '111111', :password => 'passwd'}
      get :login, :login => @user
    end

    it "レスポンスがリダイレクトであること" do
      response.should be_redirect
    end

    it "Sessionテーブルにユーザのセッションが１列追加されていること" do
      Session.find_all_by_user_code(@user[:key]).size.should == 1
    end
  end

  describe "二度目のログインの場合" do
    before(:each) do
      AccountAccess.should_receive(:auth).twice.and_return(@user_info)
      @user = { :key => '111111', :password => 'passwd' }
      get :login, :login => @user, :login_save => true
      get :login, :login => @user, :login_save => true
    end

    it "レスポンスがリダイレクトであること" do
      response.should be_redirect
    end

    it "Sessionテーブルにユーザのセッションが２列追加されていること" do
      Session.find_all_by_user_code(@user[:key]).size.should == 2
    end

    it "失効期間が１ヶ月として設定されていること" do
      assert Session.find_all_by_user_code(@user[:key]).last.expire_date > Time.now + 1.month - 1.day
      assert Session.find_all_by_user_code(@user[:key]).last.expire_date < Time.now + 1.month + 1.day
    end
  end
end
