# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
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
  # グループの一覧表示
  def index
    params[:yet_participation] ||= false
    params[:group_category_id] ||= "all"
    params[:sort_type] ||= "date"
    @format_type = params[:format_type] ||= "detail"
    @group_counts, @total_count = Group.count_by_category
    @group_categories = GroupCategory.all

    options = Group.paginate_option(session[:user_id], params)
    options[:per_page] = params[:format_type] == "list" ? 30 : 5
    @pages, @groups = paginate(:group, options)

    unless @groups && @groups.size > 0
      flash.now[:notice] = _('No matching groups found.')
    end
  end

  # tab_menu
  # グループの新規作成画面の表示
  def new
    @group = Group.new
    @group_categories = GroupCategory.all
    render(:partial => "group/form", :layout => 'layout',
            :locals => { :action_value => 'create', :submit_value => _('Create') } )
  end

  # post_action
  # グループの新規作成の処理
  def create
    @group = Group.new(params[:group])
    @group_categories = GroupCategory.all
    @group.group_participations.build(:user_id => session[:user_id], :owned => true)

    if @group.save
      flash[:notice] = _('Group was created successfully.')
      redirect_to :controller => 'group', :action => 'show', :gid => @group.gid
    else
      render(:partial => "group/form", :layout => 'layout',
              :locals => { :action_value => 'create', :submit_value => _('Create') } )
    end
  end

private
  def setup_layout
    @main_menu = @title = _('Groups')

    @tab_menu_source = [ {:label => _('Search for groups'), :options => {:action => 'index'}},
                         {:label => _('Create a new group'), :options => {:action => 'new'}} ]
  end
end
