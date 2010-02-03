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

class UsersController < ApplicationController
  before_filter :setup_layout

  # tab_menu
  def index
    @search = User.tagged(params[:tag_words], params[:tag_select]).profile_like(params[:profile_master_id], params[:profile_value]).order_last_accessed.search(params[:search])
    @search.exclude_retired ||= '1'
    @users = @search.paginate_without_retired_skip(:all, {:page => params[:page]})

    # 検索条件や表示順の条件によって、user_uidsがMASTERかNICKNAMEのどちらかしたロードされない。
    # そのためviewで正しく描画するためにreloadしておく
    @users.each{|u| u.user_uids.reload}
    flash.now[:notice] = _('User not found.') if @users.empty?
    @tags = ChainTag.popular_tag_names
    params[:tag_select] ||= "AND"
  end

  # tab_menu
  # TODO #924で画面からリンクをなくした。1.4時点で復活しない場合は削除する
  def chain_search
    @chains = Chain.order_new.paginate(:page => params[:page], :per_page => 5)

    to_user_ids = @chains.inject([]) {|result, chain| result << chain.to_user_id }
    from_user_ids = @chains.inject([]) {|result, chain| result << chain.from_user_id }

    against_chains = Chain.find(:all, :conditions =>["from_user_id in (?) and to_user_id in (?)", to_user_ids, from_user_ids]) if to_user_ids.size > 0
    against_chains ||= []

    @result = []
    @chains.each do |chain|
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
    @main_menu = @title = _('Users')
  end
end

