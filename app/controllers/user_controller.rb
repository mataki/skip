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

class UserController < ApplicationController
  include UserHelper

  before_filter :load_user, :setup_layout
  after_filter :remove_system_message, :only => %w(show blog social)

  # tab_menu
  def show
    # 紹介してくれた人一覧
    @against_chains = @user.against_chains.order_new.limit(5)
  end

  # tab_menu
  def social
    @menu = params[:menu] || "social_chain"
    partial_name = @menu

    # contens_right
    case @menu
    when "social_chain"
      prepare_chain
    when "social_chain_against"
      prepare_chain true
      partial_name = "social_chain"
    else
      render_404 and return
    end

    render :partial => partial_name, :layout => "layout"
  end

  # tab_menu
  def group
    @groups = @user.groups.active.partial_match_name_or_description(params[:keyword]).
      categorized(params[:group_category_id]).order_active.paginate(:page => params[:page], :per_page => 50)

    flash.now[:notice] = _('No matching groups found.') if @groups.empty?
  end

private
  def setup_layout
    @title = user_title @user
    @main_menu = user_main_menu @user
    @tab_menu_option = tab_menu_option
  end

  def tab_menu_option
    { :uid => @user.uid }
  end

  def redirect_to_index
    redirect_to :action => 'show', :uid => @user.uid
  end

  def prepare_chain against = false
    unless against
      left_key, right_key = "to_user_id", "from_user_id"
    else
      left_key, right_key = "from_user_id", "to_user_id"
    end

    @chains = Chain.scoped(:conditions => [left_key + " = ?", @user.id]).order_new.paginate(:page => params[:page], :per_page => 5)

    user_ids = @chains.inject([]) {|result, chain| result << chain.send(right_key) }
    against_chains = Chain.find(:all, :conditions =>[left_key + " in (?) and " + right_key + " = ?", user_ids, @user.id]) if user_ids.size > 0
    against_chains ||= []
    messages = against_chains.inject({}) {|result, chain| result ||= {}; result[chain.send(left_key)] = chain.comment; result }
    tags = against_chains.inject({}) {|result, chain| result ||= {}; result[chain.send(left_key)] = chain.tags_as_s; result }

    @result = []
    @chains.each do |chain|
      @result << {
        :from_user => chain.from_user,
        :from_message => chain.comment,
        :from_tags_as_s => chain.tags_as_s,
        :to_user => chain.to_user,
        :counter_message => messages[chain.send(right_key)] || "",
        :to_tags_as_s => tags[chain.send(right_key)] || ""
      }
    end

    flash.now[:notice] = _('There are no introductions.') if @chains.empty?
  end
end
