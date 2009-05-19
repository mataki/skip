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

class UsersController < ApplicationController
  before_filter :setup_layout

  # tab_menu
  def index
    @condition = UserSearchCondition.create_by_params params

    @pages, @users = paginate(:user,
                              :per_page => @condition.value_of_per_page,
                              :conditions => @condition.make_conditions,
                              :order_by => @condition.value_of_order_by,
                              :include => @condition.value_of_include)
    unless @users && @users.size > 0
      flash.now[:notice] = _('該当するユーザは存在しませんでした。')
    end
  end

  # tab_menu
  def chain_search
    @pages, chains = paginate(:chains,
                              :per_page => 5,
                              :order_by => "updated_on DESC")

    to_user_ids = chains.inject([]) {|result, chain| result << chain.to_user_id }
    from_user_ids = chains.inject([]) {|result, chain| result << chain.from_user_id }

    against_chains = Chain.find(:all, :conditions =>["from_user_id in (?) and to_user_id in (?)", to_user_ids, from_user_ids]) if to_user_ids.size > 0
    against_chains ||= []

    @result = []
    chains.each do |chain|
      message = ""
       against_chains.each do |ag|
         if ag.to_user_id == chain.from_user_id and ag.from_user_id == chain.to_user_id
           message = ag.comment
         end
       end

      @result << {
        :from_user => chain.from_user,
        :from_message => chain.comment,
        :to_user => chain.to_user,
        :counter_message => message
      }
    end

    render :partial => 'user/chain_table', :layout => "layout"
  end

private
  def setup_layout
    @main_menu = @title = 'ユーザ'

    @tab_menu_source = [ {:label => _('ユーザを探す'), :options => {:action => 'index'}},
                         {:label => _('紹介文'), :options => {:action => 'chain_search'}} ]
  end
end

