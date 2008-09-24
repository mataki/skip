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

# ユーザ検索時に使う検索条件クラス
class UserSearchCondition < SearchCondition

  @@keys = {:name => 'users.name', :section => 'user_profiles.section', :code => 'user_uids.uid', :introduction => 'user_profiles.self_introduction'}
  @@keys.each {|key, val| attr_reader key }

  attr_reader :include_absentee
  attr_reader :include_manager
  attr_reader :sort_type
  attr_reader :output_type
  attr_reader :not_include_retired
  attr_reader :employed_type

  class << self

    def include_manager_types
      [ ['参加者のみ', "0"],
        ['管理者を含む', "1"] ]
    end

    def sort_types
      [ ['最近ログインした順', "0"],
        ["#{Admin::Setting.login_account}順", "1"] ]
    end

    @@output_types = {
      :normal => '通常',
      :list => '一覧形式',
      :csv => 'ＣＳＶダウンロード'
    }

    def output_types options=[:normal, :list, :csv]
      output = []
      options.each do |option|
        if value = @@output_types[option]
          output << [value, option.to_s]
        end
      end
      output
    end

    def employed_types
      [['在職者・退職者含む',"0"],
       ['在職者のみ',"1"],
       ['退職者のみ',"2"]]
    end
  end

  def initialize()
    @name = @section = @code = @introduction = ""
    @conditions_state = ""

    @include_absentee = "0"
    @include_manager = "0"
    @sort_type = "0"
    @output_type = "normal"
    @not_include_retired = true
    @employed_type = "0"
  end

  def assign(params = {})
    @name = params[:name] || ""
    @section = params[:section] || ""
    @code = params[:code] || ""
    @introduction = params[:introduction] || ""

    @include_manager = params[:include_manager] || "0"
    @sort_type = params[:sort_type] || "0"
    @output_type = params[:output_type] || "normal"
    @not_include_retired = params[:not_include_retired]
    @employed_type = params[:employed_type]
  end

  def include_allusers?
    @include_absentee == "2" ? true : false
  end

  def include_manager?
    @include_manager == "1" ? true : false
  end

  def output_normal?
    @output_type == "normal" ? true : false
  end

  def value_of_order_by
    order_by = ""
    case @sort_type
    when "0"
      order_by = "user_accesses.last_access DESC"
    when "1"
      order_by = "user_uids.uid"
    end
    order_by
  end

  def value_of_per_page
    per_page = 10
    case @output_type
    when "normal"
      per_page = 5
    when "list"
      per_page = 20
    end
    per_page
  end

  def make_conditions
    conditions_param = []
    @@keys.each do |key, val|
      value = send(key)
      unless value.empty?
        conditions_state << val + " like ?"
        conditions_param << SkipUtil.to_like_query_string(value)
      end
    end
    if @not_include_retired
      conditions_state << "users.status = ?"
      conditions_param << 'ACTIVE'
    else
      conditions_state << "users.status in (?)"
      conditions_param << ['ACTIVE', 'RETIRED']
    end
    if @employed_type
      case @employed_type
        when "1"
        conditions_state << "users.status = ?"
        conditions_param << 'ACTIVE'
        when "2"
        conditions_state << "users.status = ?"
        conditions_param << 'RETIRED'
      end
    end
    if @sort_type == "1"
      conditions_state << "user_uids.uid_type = ?"
      conditions_param << UserUid::UID_TYPE[:master]
    end
    conditions_param.unshift(@conditions_state)
  end

  def value_of_include
    # パフォ劣化のため、user_uidsテーブルとの外部結合をログインIDとログインIDソートに限定した。
    include_tables = [:user_access, :pictures, :user_uids, :user_profile]
    include_tables.delete(:user_uids) if @code.empty? && @sort_type != "1"
    include_tables   
  end

  private
  def conditions_state
    unless @conditions_state.empty? 
      @conditions_state << " AND "
    end
    @conditions_state
  end     
end

