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

class GroupController < ApplicationController
  before_filter :load_group_and_participation, :setup_layout

  before_filter :check_owned,
                :only => [ :manage, :managers, :permit,
                           :update, :destroy, :toggle_owned,
                           :forced_leave_user, :change_participation, :append_user ]

  after_filter :remove_system_message, :only => %w(show users bbs)

  verify :method => :post,
         :only => [ :join, :destroy, :leave, :update, :change_participation,
                    :toggle_owned, :forced_leave_user, :append_user ],
         :redirect_to => { :action => :show }

  # tab_menu
  def show
    @owners = User.owned(@group).order_joined.limit(20)
    @except_owners = User.joined_except_owned(@group).order_joined.limit(20)
    find_params = BoardEntry.make_conditions(current_user.belong_symbols, :symbol => @group.symbol)
    @recent_messages = BoardEntry.scoped(
        :conditions => find_params[:conditions],
        :include => find_params[:include] | [ :user, :state ]
      ).order_sort_type("date").all(:limit => 10)
  end

  # tab_menu
  def users
    @users = @group.users.paginate(:page => params[:page])

    flash.now[:notice] = _('User not found.') if @users.empty?
  end

  # tab_menu
  def bbs
    options = { :symbol => @group.symbol }

    # 左側
    setup_bbs_left_box options

    # 右側
    if entry_id = params[:entry_id]
      options[:id] = entry_id
      find_params = BoardEntry.make_conditions(current_user.belong_symbols, options)

      @entry = BoardEntry.scoped(
        :conditions => find_params[:conditions],
        :include => find_params[:include] | [ :user, :board_entry_comments, :state ]
      ).order_new.first
      if @entry
        @checked_on = if reading = @entry.user_readings.find_by_user_id(current_user.id)
                        reading.checked_on
                      end
        @entry.accessed(current_user.id)
        @prev_entry, @next_entry = @entry.get_around_entry(current_user.belong_symbols)
        @editable = @entry.editable?(current_user.belong_symbols, session[:user_id], session[:user_symbol], current_user.group_symbols)
        @tb_entries = @entry.trackback_entries(current_user.id, current_user.belong_symbols)
        @to_tb_entries = @entry.to_trackback_entries(current_user.id, current_user.belong_symbols)
        @title += " - " + @entry.title

        @entry_accesses =  EntryAccess.find_by_entry_id @entry.id
        @total_count = @entry.state.access_count
        bookmark = Bookmark.find(:first, :conditions =>["url = ?", "/page/"+@entry.id.to_s])
        @bookmark_comments_count = bookmark ? bookmark.bookmark_comments_count : 0
      end
    else
      options[:category] = params[:category]
      options[:keyword] = params[:keyword]

      find_params = BoardEntry.make_conditions(current_user.belong_symbols, options)

      if user_id = params[:user_id]
        find_params[:conditions][0] << " and board_entries.user_id = ?"
        find_params[:conditions] << user_id
      end

      @entries = BoardEntry.scoped(
        :conditions => find_params[:conditions],
        :include => find_params[:include] | [ :user, :state ]
      ).order_sort_type(params[:sort_type]).aim_type(params[:type]).paginate(:page => params[:page], :per_page => 20)
    end
  end

  def new
    redirect_to_with_deny_auth and return unless current_user.group_symbols.include? @group.symbol

    redirect_to(:controller => 'edit',
                :action => 'index',
                :gid => @group.gid,
                :entry_type => BoardEntry::GROUP_BBS,
                :symbol => @group.symbol,
                :publication_type => @group.default_publication_type)
  end

  def new_notice
    redirect_to_with_deny_auth and return unless current_user.group_symbols.include? @group.symbol

    redirect_to(:controller => 'edit',
                :action => 'index',
                :gid => @group.gid,
                :entry_type => BoardEntry::GROUP_BBS,
                :aim_type => 'notice',
                :symbol => @group.symbol,
                :publication_type => @group.default_publication_type)
  end

  def new_question
    redirect_to_with_deny_auth and return unless current_user.group_symbols.include? @group.symbol

    redirect_to(:controller => 'edit',
                :action => 'index',
                :gid => @group.gid,
                :entry_type => BoardEntry::GROUP_BBS,
                :aim_type => 'question',
                :send_mail => !!params[:send_mail],
                :symbol => @group.symbol,
                :publication_type => @group.default_publication_type)
  end

  # tab_menu
  def manage
    @menu = params[:menu] || "manage_info"

    case @menu
    when "manage_info"
      @group_categories = GroupCategory.all
    when "manage_participations"
      @participations = @group.group_participations.active.paginate(:page => params[:page], :per_page => 20)
    when "manage_permit"
      unless @group.protected?
        flash[:warn] = _("No approval needed to join this group.")
        redirect_to :action => :manage
        return
      end
      @participations = @group.group_participations.waiting.paginate(:page => params[:page], :per_page => 20)
    else
      render_404 and return
    end
    render :partial => @menu, :layout => "layout"
  end

  # post_action
  # 参加申込み
  def join
    participations = @group.join current_user
    unless participations.empty?
      if participations.first.waiting?
        flash[:notice] = _('Request sent. Please wait for the approval.')
      else
        @group.group_participations.only_owned.each do |owner_participation|
          SystemMessage.create_message :message_type => 'JOIN', :user_id => owner_participation.user_id, :message_hash => {:group_id => @group.id}
        end
        flash[:notice] = _('Joined the group successfully.')
      end
    else
      flash[:error] = @group.errors.full_messages
    end
    redirect_to :action => 'show'
  end

  # 参加者追加(管理者のみ)
  def append_user
    # FIXME 管理者のみに制御出来ていない
    symbol_type, symbol_id = Symbol.split_symbol params[:symbol]
    case
    when (symbol_type == 'uid' and user = User.find_by_uid(symbol_id))
      participations = @group.join user, :force => true
      if participations.size > 0
        SystemMessage.create_message :message_type => 'FORCED_JOIN', :user_id => user.id, :message_hash => {:group_id => @group.id} 
        flash[:notice] = _("Added %s as a member.") % user.name
      else
        flash[:error] = @group.errors.full_messages
      end
    when (symbol_type == 'gid' and group = Group.active.find_by_gid(symbol_id, :include => :group_participations))
      users = group.group_participations.active.map(&:user)
      participations = @group.join users, :force => true

      participations.each do |participation|
        SystemMessage.create_message :message_type => 'FORCED_JOIN', :user_id => participation.user.id, :message_hash => {:group_id => @group.id} 
      end

      flash[:notice] = _("Added members of %s as members of the group") % group.name unless participations.empty?
      flash[:error] = @group.errors.full_messages.join("\t") unless @group.errors.empty?
    else
      flash[:warn] = _("Users / groups selection invalid.")
    end
    redirect_to :action => 'manage', :menu => 'manage_participations'
  end

  # post_action
  # 退会
  def leave
    @group.leave @participation.user do |result|
      if result
        @group.group_participations.only_owned.each do |owner_participation|
          SystemMessage.create_message :message_type => 'LEAVE', :user_id => owner_participation.user_id, :message_hash => {:user_id => current_user.id, :group_id => @group.id}
        end
        flash[:notice] = _('Successfully left the group.')
      else
        flash[:notice] = _('%s are not a member of the group.') % 'You'
      end
    end
    redirect_to :action => 'show'
  end

  # 管理者による強制退会処理
  def forced_leave_user
    # FIXME 管理者のみに制御出来ていない
    group_participation = GroupParticipation.find(params[:participation_id])
    @group.leave group_participation.user do |result|
      if result
        SystemMessage.create_message :message_type => 'FORCED_LEAVE', :user_id => group_participation.user.id, :message_hash => {:group_id => @group.id}
        flash[:notice] = _("Removed %s from members of the group.") % group_participation.user.name
      else
        flash[:notice] = _('%s are not a member of the group.') % group_participation.user.name
      end
    end
    redirect_to :action => 'manage', :menu => 'manage_participations'
  end

  # post_action ... では無いので後に修正が必要
  # 管理者変更
  def toggle_owned
    group_participation = GroupParticipation.find(params[:participation_id])

    redirect_to_with_deny_auth and return unless group_participation.user_id != session[:user_id]

    group_participation.owned = !group_participation.owned?

    if group_participation.save
      flash[:notice] = _('Changed.')
    else
      flash[:warn] = _('Failed to change status.')
    end
    redirect_to :action => 'manage', :menu => 'manage_participations'
  end

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

  # post_action
  # 更新
  def update
    if @group.update_attributes(params[:group])
      flash.now[:notice] = _('Group information was successfully updated.')
    end
    manage
  end

  # post_action
  # 削除
  def destroy
    if @group.group_participations.size > 1
      flash[:warn] = _('Failed to delete since there are still other users in the group.')
      redirect_to :action => 'show'
    else
      @group.logical_destroy
      flash[:notice] = _('Group was successfully deleted.')
      redirect_to :controller => 'groups'
    end
  end

private
  def setup_layout
    @title = title
    @main_menu = main_menu
    @tab_menu_option = tab_menu_option
  end

  def main_menu
    _('Groups')
  end

  def title
    @group.name if @group
  end

  def tab_menu_option
    { :gid => @group.gid }
  end

  def load_group_and_participation
    unless @group = current_target_group
      flash[:warn] = _("Specified group does not exist.")
      redirect_to :controller => 'mypage', :action => 'index'
      return false
    end
    @participation = current_participation
  end

  def check_owned
    unless @participation and @participation.owned?
      flash[:warn] = _('Administrative privillage required for the action.')
      redirect_to :controller => 'mypage', :action => 'index'
      return false
    end
  end

  def setup_bbs_left_box options
    find_params = BoardEntry.make_conditions(current_user.belong_symbols, options)

    # 人毎のアーカイブ
    select_state = "count(distinct board_entries.id) as count, users.name as user_name, users.id as user_id"
    joins_state = "LEFT OUTER JOIN entry_publications ON entry_publications.board_entry_id = board_entries.id"
    joins_state << " LEFT OUTER JOIN users ON users.id = board_entries.user_id"
    @user_archives = BoardEntry.find(:all,
                                     :select => select_state,
                                     :conditions=> find_params[:conditions],
                                     :group => "user_id",
                                     :order => "count desc",
                                     :joins => joins_state)
  end

end
