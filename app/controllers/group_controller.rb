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

class GroupController < ApplicationController
  before_filter :setup_layout

  before_filter :check_owned,
                :only => [ :permit, :change_participation ]

  verify :method => :post, :only => [ :change_participation ], :redirect_to => { :action => :show }

#  # 参加者追加(管理者のみ)
#  def append_user
#    # FIXME 管理者のみに制御出来ていない
#    symbol_type, symbol_id = Symbol.split_symbol params[:symbol]
#    case
#    when (symbol_type == 'gid' and group = Group.active.find_by_gid(symbol_id, :include => :group_participations))
#      users = group.group_participations.active.map(&:user)
#      participations = @group.join users, :force => true
#
#      participations.each do |participation|
#        SystemMessage.create_message :message_type => 'FORCED_JOIN', :user_id => participation.user.id, :message_hash => {:group_id => @group.id} 
#      end
#
#      flash[:notice] = _("Added members of %s as members of the group") % group.name unless participations.empty?
#      flash[:error] = @group.errors.full_messages.join("\t") unless @group.errors.empty?
#    else
#      flash[:warn] = _("Users / groups selection invalid.")
#    end
#    redirect_to :action => 'manage', :menu => 'manage_participations'
#  end

#  # post_action ... では無いので後に修正が必要
#  # 管理者変更
#  def toggle_owned
#    group_participation = GroupParticipation.find(params[:participation_id])
#
#    redirect_to_with_deny_auth and return unless group_participation.user_id != session[:user_id]
#
#    group_participation.owned = !group_participation.owned?
#
#    if group_participation.save
#      flash[:notice] = _('Changed.')
#    else
#      flash[:warn] = _('Failed to change status.')
#    end
#    redirect_to :action => 'manage', :menu => 'manage_participations'
#  end

  # post_action
  # 参加の許可か棄却
  # TODO 参加許可、参加棄却は別のactionにしたい。
  def change_participation
    unless @group.protected?
      flash[:warn] = _("No approval needed to join this group.")
      redirect_to :action => :show
      return
    end

    participation_ids = if states = params[:participation_state]
                          participation_ids = states.map { |participation_id, state| participation_id.to_i if state == 'true' }.compact
                        end || []
    # 処理対象がない
    if participation_ids.empty?
      redirect_to :action => 'manage', :menu => 'manage_permit'
      return
    end

    # 処理対象に既に参加状態になっているものがある
    if participation_ids.any? {|participation_id| @group.group_participations.active.map(&:id).include? participation_id }
      flash[:warn] = _("Part of the users are already members of this group.")
      redirect_to :action => 'manage', :menu => 'manage_permit'
      return
    end

    target_participations = @group.group_participations.waiting.map do |participation|
      participation if participation_ids.include?(participation.id)
    end.compact

    if params[:submit_type] == 'permit'
      begin
        GroupParticipation.transaction do
          target_participations.each do |participation|
            participation.waiting = false
            participation.save!
            participation.user.notices.create!(:target => @group) unless participation.user.notices.find_by_target_id(@group.id)
          end
          target_participations.each do |participation|
            SystemMessage.create_message :message_type => 'APPROVAL_OF_JOIN', :user_id => participation.user.id, :message_hash => {:group_id => @group.id}
          end
          flash[:notice] = _("Succeeded to Approve.")
        end
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
        flash[:notice] = _("Failed to Approve.")
      end
    else
      target_participations.each do |participation|
        participation.destroy
        SystemMessage.create_message :message_type => 'DISAPPROVAL_OF_JOIN', :user_id => participation.user.id, :message_hash => {:group_id => @group.id}
      end
      flash[:notice] = _("Succeeded to Disapprove.")
    end
    redirect_to :action => 'manage', :menu => 'manage_permit'
  end

private
  def setup_layout
    @title = title
    @main_menu = main_menu
  end

  def main_menu
    _('Groups')
  end

  def title
    @group.name if @group
  end

  def check_owned
    unless @participation and @participation.owned?
      flash[:warn] = _('Administrative privillage required for the action.')
      redirect_to :controller => 'mypage', :action => 'index'
      return false
    end
  end

end
