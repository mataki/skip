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

class ChainsController < ApplicationController
  include UsersHelper

  before_filter :setup_layout
  after_filter :make_chain_message, :only => [:create, :update]
  after_filter :remove_system_message, :only => %w(index against)

  def index
    prepare_chain
  end

  # TODO searchlogicベースにしてagainstはなくしたい
  # TODO prepare_chainはなくしたい
  def against
    prepare_chain true
    render :index
  end

  def new
    @chain = current_user.follow_chains.build
    respond_to do |format|
      format.html
    end
  end

  def edit
    @chain = current_chain
    respond_to do |format|
      format.html { @chain ? render : render_404 }
    end
  end

  def create
    @chain = current_user.follow_chains.build(params[:chain])
    @chain.to_user = current_target_user

    respond_to do |format|
      if @chain.save
        format.html do
          flash[:notice] = _('Introduction was created successfully.')
          redirect_to tenant_user_url(current_tenant, current_target_user)
        end
      else
        format.html do
          render :new
        end
      end
    end
  end

  def update
    @chain = current_chain

    respond_to do |format|
      if @chain.update_attributes(params[:chain])
        format.html do
          flash[:notice] = _('Introduction was updated successfully.')
          redirect_to tenant_user_url(current_tenant, current_target_user)
        end
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    @chain = current_chain
    @chain.destroy
    respond_to do |format|
      format.html do
        flash[:notice] = _('Introduction was deleted successfully.')
        redirect_to tenant_user_url(current_tenant, current_target_user)
      end
    end
  end

  private
  def setup_layout
    @title = user_title current_target_user
    @main_menu = user_main_menu current_target_user
    @tab_menu_option = { :uid => current_target_user.uid }
  end

  def make_chain_message
    return unless @chain
    SystemMessage.create_message :message_type => 'CHAIN', :user_id => current_target_user.id, :message_hash => {:user_id => current_target_user.id}
  end

  def current_chain
    @chain ||= current_user.follow_chains.find_by_to_user_id current_target_user.id
    raise ActiveRecord::RecordNotFound unless @chain
    @chain
  end

  def prepare_chain against = false
    unless against
      left_key, right_key = "to_user_id", "from_user_id"
    else
      left_key, right_key = "from_user_id", "to_user_id"
    end

    @chains = Chain.scoped(:conditions => [left_key + " = ?", current_target_user.id]).order_new.paginate(:page => params[:page], :per_page => 5)

    user_ids = @chains.inject([]) {|result, chain| result << chain.send(right_key) }
    against_chains = Chain.find(:all, :conditions =>[left_key + " in (?) and " + right_key + " = ?", user_ids, current_target_user.id]) if user_ids.size > 0
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
