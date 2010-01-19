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
  include UserHelper

  before_filter :load_user, :setup_layout
  after_filter :make_chain_message, :only => [:create, :update]

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
          redirect_to current_target_user_url
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
          redirect_to current_target_user_url
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
        redirect_to current_target_user_url
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

  # TODO usersを完全にmap_resouceベースにしたら標準のメソッドを利用するように変更する
  def current_target_user_url
    { :controller => 'user', :action => 'show', :uid => current_target_user.uid }
  end
end
