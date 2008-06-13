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

class GroupsController < ApplicationController
  before_filter :setup_layout

  verify :method => :post, :only => [ :create ],
         :redirect_to => { :action => :index }

  # tab_menu
  def index
    params[:yet_participation] ||= false
    target_user_id = params[:user_id] || session[:user_id]
    params[:category] ||= "all"
    params[:format_type] ||= "detail"
    @format_type = params[:format_type]
    @group_counts, @total_count = Group.count_by_category
    params[:sort_type] ||= "date"

    @pages, @groups = paginate_groups(target_user_id, params)
    unless @groups && @groups.size > 0
      flash.now[:notice] = '該当するグループはありませんでした。'
    end
  end

  # tab_menu
  def pages_search
    redirect_to :controller => 'search', :action => 'index', :group => '1'
  end

  # tab_menu
  # グループの新規作成画面の表示
  def new
    @group = Group.new
    @group.category = Group::LIFE
    render_create
  end

  # post_action
  # グループの新規作成の処理
  def create
    @group = Group.new(params[:group])
      #管理者（自分）
      @group.group_participations.build(:user_id => session[:user_id], :owned => true)

      # 招待したいユーザ・グループ
      default_users = []
      params[:publication_symbols_value].split(',').each do |symbol|
        symbol_id = symbol.split(":").last
        if symbol.include?("gid:")
          group = Group.find_by_gid(symbol_id, :include => :group_participations)
          group.group_participations.each { |gp| default_users << gp.user_id } if group
        elsif symbol.include?("uid:")
          user = User.find_by_uid(symbol_id)
          default_users << user.id if user
        end
      end

      default_users.delete(session[:user_id]) # ログインユーザのIDは既に登録済み
      default_users.uniq.each { |user_id| @group.group_participations.build(:user_id => user_id, :owned => false)}

      if @group.save
        flash[:notice] = 'グループが正しく作成されました。'
        redirect_to :controller => 'group', :action => 'show', :gid => @group.gid
        return
      end
    render_create
  end

  # component
  def list
    if not parent_controller
      flash[:warning] = '不正な操作でのアクセスは許可されていません'
      redirect_to :controller => 'mypage', :action => "index"
      return
    end

    params[:page] = parent_controller.params[:page]
    params[:participation] = true
    show_user_id = parent_controller.params[:user_id]
    params[:keyword] = parent_controller.params[:keyword]
    params[:category] = parent_controller.params[:category]
    @format_type = params[:format_type] = parent_controller.params[:format_type]
    params[:sort_type] = parent_controller.params[:sort_type] || "date"

    @pages, @groups = paginate_groups(show_user_id, params)
    unless @groups && @groups.size > 0
      flash.now[:notice] = '該当するグループはありませんでした。'
    end

    params[:controller] = parent_controller.params[:controller]
    params[:action] = parent_controller.params[:action]

    render :partial => 'groups', :object => @groups, :locals => { :pages => @pages,
                                                                  :user_id => params[:user_id],
                                                                  :show_favorite => (show_user_id == session[:user_id]) }
  end

private
  def setup_layout
    @main_menu = @title = 'グループ'

    @tab_menu_source = [ ['トップ', 'index'],
                         ['掲示板検索', 'pages_search'],
                         ['グループの新規作成', 'new'] ]
  end

  def render_create
    render(:partial => "group/form",
           :layout => 'layout',
           :locals => { :action_value => 'create', :submit_value => '作成' } )
  end

  def paginate_groups target_user_id, params = { :page => 1 }

    conditions = [""]

    if params[:keyword] and not params[:keyword].empty?
      conditions[0] << "(groups.name like ? or groups.description like ?)"
      conditions << SkipUtil.to_lqs(params[:keyword]) << SkipUtil.to_lqs(params[:keyword])
    end

    if params[:yet_participation]
      conditions[0] << " and " unless conditions[0].empty?
      conditions[0] << " NOT EXISTS (SELECT * FROM group_participations gp where groups.id = gp.group_id and gp.user_id = ?) "
      conditions << target_user_id
    elsif params[:participation]
      conditions[0] << " and " unless conditions[0].empty?
      conditions[0] << " group_participations.user_id in (?)"
      conditions << target_user_id
    end

    if category = params[:category] and category != "all"
      conditions[0] << " and " unless conditions[0].empty?
      conditions[0] << "category = ?"
      conditions << category
    end

    options = {
      :per_page => params[:format_type] == "list" ? 30 : 5,
      :include => :group_participations
    }
    if sort_type = params[:sort_type]
      case sort_type
      when "date"
        options[:order] = "group_participations.created_on DESC"
      when "name"
        options[:order] = "groups.name"
      else
        options[:order] = "group_participations.created_on DESC"
      end
    end

    options[:conditions] = conditions unless conditions[0].empty?

    return paginate(:group, options)
  end
end
