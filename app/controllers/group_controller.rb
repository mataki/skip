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

  verify :method => :post,
         :only => [ :join, :destroy, :leave, :update, :change_participation,
                    :toggle_owned, :forced_leave_user, :append_user ],
         :redirect_to => { :action => :show }
  N_('GroupController|ApproveSuceeded')
  N_('GroupController|ApproveFailed')
  N_('GroupController|DisapproveSuceeded')
  N_('GroupController|DispproveFailed')

  # tab_menu
  def show
    @owners = User.owned(@group).order_joined.limit(20)
    @except_owners = User.joined_except_owned(@group).order_joined.limit(20)
    @recent_messages = BoardEntry.find_visible(10, login_user_symbols, @group.symbol)
  end

  # tab_menu
  def users
    params[:condition] = {} unless params[:condition]
    params[:condition].merge!(:with_group => @group.id, :include_manager => '1')
    @condition = UserSearchCondition.create_by_params params

    @users = User.scoped(
      :conditions => @condition.make_conditions,
      :include => @condition.value_of_include,
      :order => @condition.value_of_order_by
    ).paginate(:page => params[:page], :per_page => @condition.value_of_per_page)

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
      find_params = BoardEntry.make_conditions(login_user_symbols, options)

      @entry = BoardEntry.scoped(
        :conditions => find_params[:conditions],
        :include => find_params[:include] | [ :user, :board_entry_comments, :state ]
      ).order_new.first
      if @entry
        @checked_on = @entry.accessed(current_user.id).checked_on
        @prev_entry, @next_entry = @entry.get_around_entry(login_user_symbols)
        @editable = @entry.editable?(login_user_symbols, session[:user_id], session[:user_symbol], login_user_groups)
        @tb_entries = @entry.trackback_entries(current_user.id, login_user_symbols)
        @to_tb_entries = @entry.to_trackback_entries(current_user.id, login_user_symbols)
        @title += " - " + @entry.title

        @entry_accesses =  EntryAccess.find_by_entry_id @entry.id
        @total_count = @entry.state.access_count
        bookmark = Bookmark.find(:first, :conditions =>["url = ?", "/page/"+@entry.id.to_s])
        @bookmark_comments_count = bookmark ? bookmark.bookmark_comments_count : 0
      end
    else
      options[:category] = params[:category]
      options[:keyword] = params[:keyword]

      find_params = BoardEntry.make_conditions(login_user_symbols, options)

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
    redirect_to_with_deny_auth and return unless login_user_groups.include? @group.symbol

    redirect_to(:controller => 'edit',
                :action => 'index',
                :entry_type => BoardEntry::GROUP_BBS,
                :symbol => @group.symbol,
                :publication_type => @group.default_publication_type)
  end

  def new_notice
    redirect_to_with_deny_auth and return unless login_user_groups.include? @group.symbol

    redirect_to(:controller => 'edit',
                :action => 'index',
                :entry_type => BoardEntry::GROUP_BBS,
                :aim_type => 'notice',
                :symbol => @group.symbol,
                :publication_type => @group.default_publication_type)
  end

  def new_question
    redirect_to_with_deny_auth and return unless login_user_groups.include? @group.symbol

    redirect_to(:controller => 'edit',
                :action => 'index',
                :entry_type => BoardEntry::GROUP_BBS,
                :aim_type => 'question',
                :send_mail => !!params[:send_mail],
                :symbol => @group.symbol,
                :publication_type => @group.default_publication_type)
  end

  # tab_menu
  def new_participation
    render :layout => 'dialog'
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
    if @participation
      flash[:notice] = _('You are already a member of the group.')
    else
      participation = GroupParticipation.new(:user_id => session[:user_id], :group_id => @group.id)
      participation.waiting = true if @group.protected?

      if participation.save
        if participation.waiting?
          flash[:notice] = _('Request sent. Please wait for the approval.')
        else
          login_user_groups << @group.symbol
          flash[:notice] = _('Joined the group successfully.')
        end

        message = params[:board_entry][:contents]

        #グループのownerのシンボル(複数と取ってきて、publication_symbolsに入れる)
        owner_symbols = @group.owners.map { |user| user.symbol }
        entry_params = { }
        entry_params[:title] = _("Request to join the group has been sent out!")
        entry_params[:message] = render_to_string(:partial => 'entries_template/group_join',
                                                  :locals => { :user_name => current_user.name,
                                                               :message => message })
        # TODO 国際化を踏まえた仕様の再検討を行う
        # _('Request to Join Group')としたいが、タグのvalidateでspaceを許可していないためエラーになる。
        # また、「参加申し込み」タグは一部システム的な動作(著者毎の記事一覧から除外)を
        # 行っているため、国際化を踏まえた仕様を再検討しなければならない。
        entry_params[:tags] = '参加申し込み'
        entry_params[:aim_type] = 'notice' if @group.protected?
        entry_params[:user_symbol] = session[:user_symbol]
        entry_params[:user_id] = session[:user_id]
        entry_params[:entry_type] = BoardEntry::GROUP_BBS
        entry_params[:owner_symbol] = @group.symbol
        entry_params[:publication_type] = 'protected'
        entry_params[:publication_symbols] = owner_symbols + [session[:user_symbol]]

        board_entry =  BoardEntry.create_entry(entry_params)
      end
    end
    redirect_to :action => 'show'
  end

  # post_action
  # 退会
  def leave
    if @participation
      @participation.destroy
      login_user_groups.delete(@group.symbol)
      flash[:notice] = _('Successfully left the group.')
    else
      flash[:notice] = _('You are not a member of the group.')
    end
    redirect_to :action => 'show'
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

  # 管理者による強制退会処理
  def forced_leave_user
    group_participation = GroupParticipation.find(params[:participation_id])

    redirect_to_with_deny_auth and return unless group_participation.group_id == @participation.group_id

    user = group_participation.user
    group_participation.destroy

    # BBSにuid直接指定のお知らせを新規投稿(自動で投稿されて保存される)
    entry_params = { }
    entry_params[:title] =_("Leave [%s]") % @group.name
    entry_params[:message] = _("Removed %{user} from [%{group}>]") % {:group => @group.symbol, :user => user.name}
    entry_params[:aim_type] = 'notice'
    entry_params[:user_symbol] = session[:user_symbol]
    entry_params[:user_id] = session[:user_id]
    entry_params[:entry_type] = BoardEntry::GROUP_BBS
    entry_params[:owner_symbol] = @group.symbol
    entry_params[:publication_type] = 'protected'
    entry_params[:publication_symbols] = [session[:user_symbol]]
    entry_params[:publication_symbols] << user.symbol
    entry = BoardEntry.create_entry(entry_params)

    flash[:notice] = _("Created an entry on the forum about the removal of user. Edit the entry when needed.")
    redirect_to :action => 'bbs', :entry_id => entry.id
  end

  # post_action
  # 参加の許可か棄却
  def change_participation
    unless @group.protected?
      flash[:warn] = _("No approval needed to join this group.")
      redirect_to :action => :show
    end
    type_name = params[:submit_type] == 'permit' ? s_('GroupController|Approve') : s_('GroupController|Disapprove') #"許可" : "棄却"

    if states = params[:participation_state]
      states.each do |participation_id, state|
        if state == 'true'
          participation = GroupParticipation.find(participation_id)
          if participation.group_id == @participation.group_id &&
            !participation.waiting
            flash[:warn] = _("Part of the users are already members of this group.")
            redirect_to :action => 'manage', :menu => 'manage_permit'
            return false
          end
          result = nil
          if params[:submit_type] == 'permit'
            participation.waiting = false
            result = participation.save
          else
            result = participation.destroy
          end

          flash[:notice] = _("%{rslt} to %{type}.") % {:type => type_name, :rslt => result ? _('Succeeded') : _('Failed')} #'しました' : 'に失敗しました。'
        end
      end
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

  # 参加者追加(管理者のみ)
  def append_user
    # 参加制約は追加しない。制約は制約管理で。
    symbol_type, symbol_id = Symbol.split_symbol params[:symbol]
    case
    when (symbol_type == 'uid' and user = User.find_by_uid(symbol_id))
      if @group.group_participations.find_by_user_id(user.id)
        flash[:notice] = _("%s has already joined / applied to join this group.") % user.name
      else
        @group.group_participations.build(:user_id => user.id, :owned => false)
        @group.save
        flash[:notice] = _("Added %s as a member and created a forum for messaging.") % user.name
      end
    when (symbol_type == 'gid' and group = Group.active.find_by_gid(symbol_id, :include => :group_participations))
      group.group_participations.each do |participation|
        unless @group.group_participations.find_by_user_id(participation.user_id)
          @group.group_participations.build(:user_id => participation.user_id, :owned => false)
        end
      end
      @group.save
      flash[:notice] = _("Added members of %s as members of the group and created a forum for messaging.") % group.name
    else
      flash[:warn] = _("Users / groups selection invalid.")
    end

    # BBSにsymbol直接指定[連絡]で新規投稿(自動で投稿されて保存される)
    @group.create_entry_invite_group(session[:user_id],
                                     session[:user_symbol],
                                     [params[:symbol], session[:user_symbol]])

    redirect_to :action => 'manage', :menu => 'manage_participations'
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
    unless @group = Group.active.find_by_gid(params[:gid])
      flash[:warn] = _("Specified group does not exist.")
      redirect_to :controller => 'mypage', :action => 'index'
      return false
    end
    @participation = @group.group_participations.find_by_user_id(current_user.id)
  end

  def check_owned
    unless @participation and @participation.owned?
      flash[:warn] = _('Administrative privillage required for the action.')
      redirect_to :controller => 'mypage', :action => 'index'
      return false
    end
  end

  def setup_bbs_left_box options
    find_params = BoardEntry.make_conditions(login_user_symbols, options)
    # カテゴリ
    @categories = BoardEntry.get_category_words(find_params)

    # 人毎のアーカイブ
    select_state = "count(distinct board_entries.id) as count, users.name as user_name, users.id as user_id"
    joins_state = "LEFT OUTER JOIN entry_publications ON entry_publications.board_entry_id = board_entries.id"
    joins_state << " LEFT OUTER JOIN users ON users.id = board_entries.user_id"
    find_params[:conditions].first << " and category not like '%[参加申し込み]%'"
    @user_archives = BoardEntry.find(:all,
                                     :select => select_state,
                                     :conditions=> find_params[:conditions],
                                     :group => "user_id",
                                     :order => "count desc",
                                     :joins => joins_state)
  end

end
