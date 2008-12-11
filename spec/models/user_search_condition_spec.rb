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

describe UserSearchCondition do
  describe "パラメータが設定されていない場合" do
    it "初期値がロードされること" do
      conditions = UserSearchCondition.create_by_params :condition => {}
      conditions.value_of_per_page.should == 5
      conditions.make_conditions.should == ["users.status in (?)", ["ACTIVE", "RETIRED"]]

      conditions.value_of_order_by.should == "user_accesses.last_access DESC"
      conditions.value_of_include.should == [:user_access, :pictures]
    end
  end
  describe "名前が検索条件になっている場合" do
    it "検索条件が設定されていること" do
      conditions = UserSearchCondition.create_by_params :condition => { :name => "name" }
      conditions.make_conditions.should == ["users.name like ? AND users.status in (?)", "%name%", ["ACTIVE", "RETIRED"]]
    end
  end
  describe "部門が検索条件になっている場合" do
    it "検索条件が設定されていること" do
      conditions = UserSearchCondition.create_by_params :condition => { :section => "section" }
      conditions.make_conditions.should == ["users.section like ? AND users.status in (?)", "%section%", ["ACTIVE", "RETIRED"]]
    end
  end
  describe "ログインID/ユーザ名が検索条件になっている場合" do
    it "検索条件が設定されていること" do
      conditions = UserSearchCondition.create_by_params :condition => { :code => "code" }
      conditions.make_conditions.should == ["user_uids.uid like ? AND users.status in (?)", "%code%", ["ACTIVE", "RETIRED"]]
    end
  end
  describe "ソート順がログインID順の場合" do
    before do
      @conditions = UserSearchCondition.create_by_params :condition => { :sort_type => "1" }
    end
    it "order_byが設定されていること" do
      @conditions.value_of_order_by.should == "user_uids.uid"
    end
    it "検索条件が設定されていること" do
      @conditions.make_conditions.should == ["users.status in (?) AND user_uids.uid_type = ?", ["ACTIVE", "RETIRED"], "MASTER"]
    end
    it "includeが設定されていること" do
      @conditions.value_of_include.should == [:user_access, :pictures, :user_uids]
    end
  end
  describe "ソート順がユーザ名順の場合" do
    before do
      @conditions = UserSearchCondition.create_by_params :condition => { :sort_type => "2" }
    end
    it "order_byが設定されていること" do
      @conditions.value_of_order_by.should == "user_uids.uid"
    end
    it "検索条件が設定されていること" do
      @conditions.make_conditions.should == ["users.status in (?) AND user_uids.uid_type = ?", ["ACTIVE", "RETIRED"], "NICKNAME"]
    end
    it "includeが設定されていること" do
      @conditions.value_of_include.should == [:user_access, :pictures, :user_uids]
    end
  end
  describe "出力形式が一覧の場合" do
    it "per_pageが設定されていること" do
      conditions = UserSearchCondition.create_by_params :condition => { :output_type => "list" }
      conditions.value_of_per_page.should == 20
    end
  end
  describe "退職者を含める場合" do
    it "検索条件が設定されていること" do
      conditions = UserSearchCondition.create_by_params :condition => { :not_include_retired => "1" }
      conditions.make_conditions.should == ["users.status = ?", "ACTIVE"]
    end
  end
  describe "グループの所属情報も含めて検索する場合" do
    before do
      @conditions = UserSearchCondition.create_by_params :condition => { :with_group => 2, :include_manager => "1" }
    end
    it "検索条件が設定されていること" do
      @conditions.make_conditions.should == ["users.status in (?) AND group_participations.group_id = ? AND group_participations.waiting = false", ["ACTIVE", "RETIRED"], 2]
    end
    it "includeが設定されていること" do
      @conditions.value_of_include.should == [:user_access, :pictures, :group_participations]
    end
    describe "グループの管理者を含まない場合" do
      before do
        @conditions = UserSearchCondition.create_by_params :condition => { :with_group => 2, :include_manager => "0" }
      end
      it "検索条件が設定されていること" do
        @conditions.make_conditions.should == ["users.status in (?) AND group_participations.group_id = ? AND group_participations.waiting = false AND group_participations.owned = false", ["ACTIVE", "RETIRED"], 2]
      end
    end
  end
end
