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

  attr_reader :include_manager
  attr_reader :sort_type
  attr_reader :output_type
  attr_reader :not_include_retired
  attr_reader :with_group

  class << self
    include InitialSettingsHelper

    def include_manager_types
      [ [_('Members Only'), "0"],
        [_('Including Administrators'), "1"] ]
    end

    def sort_types
      options = [ [_('Sort by last login'), "0"] ]
      options << [_("Sort by %s") % Admin::Setting.login_account, "1"] if user_name_mode?(:code)
      options << [_('Sort by user name'), "2"] if user_name_mode?(:name)
      options
    end

    def output_types
      [ [_('Normal View'), 'normal'],
        [_('List View'), 'list'] ]
    end
  end

  def initialize
    @name = @section = @code = @introduction = ""
    @conditions_state = ""

    @include_manager = "0"
    @sort_type = "0"
    @output_type = "normal"
    @not_include_retired = true
    @with_group = nil
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
    @with_group = params[:with_group]
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
    when "1", "2"
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
    if @sort_type
      case @sort_type
      when "1"
        conditions_state << "user_uids.uid_type = ?"
        conditions_param << UserUid::UID_TYPE[:master]
      when "2"
        conditions_state << "user_uids.uid_type = ?"
        conditions_param << UserUid::UID_TYPE[:username]
      end
    end
    if @with_group
      conditions_state << "group_participations.group_id = ? AND group_participations.waiting = false"
      conditions_param << @with_group
      unless @include_manager == "1"
        conditions_state << "group_participations.owned = false"
      end
    end
    conditions_param.unshift(@conditions_state)
  end

  def value_of_include
    # パフォ劣化のため、user_uidsテーブルとの外部結合をログインIDとログインIDソートに限定した。
    include_tables = [:user_access, :pictures, :user_uids, :user_profile]
    include_tables.delete(:user_uids) if @code.empty? && @sort_type == "0"
    include_tables << :group_participations if @with_group
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
