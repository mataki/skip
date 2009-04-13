# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008 TIS Inc.
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
  helper 'board_entries'
  before_filter :load_group_and_participation, :setup_layout

  before_filter :check_owned,
                :only => [ :manage, :managers, :permit,
                           :update, :destroy, :toggle_owned,
                           :forced_leave_user, :change_participation, :append_user ]

  verify :method => :post,
         :only => [ :join, :destroy, :leave, :update, :change_participation,
                    :ado_set_favorite, :toggle_owned, :forced_leave_user, :append_user ],
         :redirect_to => { :action => :show }

  # tab_menu
  def show
    @admin_users = @group.participation_users :order => "group_participations.updated_on DESC",
                                              :owned => true,
                                              :waiting => false
    @users = @group.participation_users :limit => 20,
                                        :order => "group_participations.updated_on DESC",
                                        :owned => false,
                                        :waiting => false
    @recent_messages = BoardEntry.find_visible(10, login_user_symbols, @group.symbol)
  end

  # tab_menu
  def users
    params[:condition] = {} unless params[:condition]
    params[:condition].merge!(:with_group => @group.id)
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
  def bbs
    order = "last_updated DESC,board_entries.id DESC"
    options = { :symbol => @group.symbol }

    # 左側
    setup_bbs_left_box options

    # 右側
    if entry_id = params[:entry_id]
      options[:id] = entry_id
      find_params = BoardEntry.make_conditions(login_user_symbols, options)

      @entry = BoardEntry.find(:first,
                               :order => order,
                               :conditions => find_params[:conditions],
                               :include => find_params[:include] | [ :user, :board_entry_comments, :state ])

      if @entry
        user_reading = UserReading.find_by_user_id_and_board_entry_id(current_user.id, @entry.id)
        @checked_on = user_reading.checked_on if user_reading
        @entry.accessed(current_user.id)
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

      params[:sort_type] ||= "date"
      if params[:sort_type] == "access"
        order = "board_entry_points.access_count DESC"
      end

      find_params = BoardEntry.make_conditions(login_user_symbols, options)

      if @user = params[:user]
        find_params[:conditions][0] << " and board_entries.user_id = ?"
        find_params[:conditions] << @user
      end

      @pages, @entries = paginate(:board_entries,
                                  :per_page => 20,
                                  :order => order,
                                  :conditions => find_params[:conditions],
                                  :include => find_params[:include] | [ :user, :board_entry_comments, :state ])
    end

  end

  # tab_menu
  def new
    redirect_to_with_deny_auth and return unless login_user_groups.include? @group.symbol

    redirect_to(:controller => 'edit',
                :action => '',
                :entry_type => BoardEntry::GROUP_BBS,
                :symbol => @group.symbol,
                :publication_type => "private")
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
      @pages, @participations = paginate_participations(@group, false)
    when "manage_permit"
      unless @group.protected?
        flash[:warning] = "参加に承認は不要です"
        redirect_to :action => :manage
        return
      end
      @pages, @participations = paginate_participations(@group, true)
    end
    render :partial => @menu, :layout => "layout"
  end

  # tab_menu
  def share_file
    params.store(:owner_name, @group.name)
    params.store(:visitor_is_uploader, @group.participating?(current_user))
    text = render_component_as_string :controller => 'share_file', :action => 'list', :id => @group.symbol, :params => params
    render :text => text, :layout => false
  end

  # post_action
  # 参加申込み
  def join
    if @participation
      flash[:notice] = '既に参加しています。'
    else
      participation = GroupParticipation.new(:user_id => session[:user_id], :group_id => @group.id)
      participation.waiting = true if @group.protected?

      if participation.save
        if participation.waiting?
          flash[:notice] = '参加申し込みをしました。承認されるのをお待ちください。'
        else
          login_user_groups << @group.symbol
          flash[:notice] = 'グループに参加しました。'
        end

        message = params[:board_entry][:contents]

        #グループのownerのシンボル(複数と取ってきて、publication_symbolsに入れる)
        owner_symbols = @group.get_owners.map { |user| user.symbol }
        entry_params = { }
        entry_params[:title] = "参加申し込みをしました！"
        entry_params[:message] = render_to_string(:partial => 'entries_template/group_join',
                                                  :locals => { :user_name => current_user.name,
                                                               :message => message })
        entry_params[:tags] = "参加申し込み"
        entry_params[:tags] << ",#{Tag::NOTICE_TAG}" if @group.protected?
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
      flash[:notice] = '退会しました。'
    else
      flash[:notice] = 'そのグループには参加していません。'
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
      flash[:notice] = '変更しました。'
    else
      flash[:warning] = '権限変更に失敗しました。'
    end
    redirect_to :action => 'manage', :menu => 'manage_participations'
  end

  # 管理者による強制退会処理
  def forced_leave_user
    group_participation = GroupParticipation.find(params[:participation_id])

    redirect_to_with_deny_auth and return unless group_participation.group_id == @participation.group_id

    user = group_participation.user
    group_participation.destroy

    # BBSにuid直接指定[連絡]で新規投稿(自動で投稿されて保存される)
    entry_params = { }
    entry_params[:title] ="【#{@group.name}】退会処理"
    entry_params[:message] = "[#{@group.symbol}>]から#{user.name}さんの退会処理を実行しました"
    entry_params[:tags] = "#{Tag::NOTICE_TAG}"
    entry_params[:user_symbol] = session[:user_symbol]
    entry_params[:user_id] = session[:user_id]
    entry_params[:entry_type] = BoardEntry::GROUP_BBS
    entry_params[:owner_symbol] = @group.symbol
    entry_params[:publication_type] = 'protected'
    entry_params[:publication_symbols] = [session[:user_symbol]]
    entry_params[:publication_symbols] << user.symbol
    entry = BoardEntry.create_entry(entry_params)

    flash[:notice] = "退会者向けに掲示板にメッセージを作成しました。内容は必要に応じて変更してください"
    redirect_to :action => 'bbs', :entry_id => entry.id
  end

  # post_action
  # 参加の許可か棄却
  def change_participation
    unless @group.protected?
      flash[:warning] = "参加に承認は不要です"
      redirect_to :action => :show
    end
    type_name = params[:submit_type] == 'permit' ? "許可" : "棄却"

    if states = params[:participation_state]
      states.each do |participation_id, state|
        if state == 'true'
          participation = GroupParticipation.find(participation_id)
          if participation.group_id == @participation.group_id &&
            !participation.waiting
            flash[:warning] = "このグループに参加済みのユーザが含まれています。"
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

          flash[:notice] = type_name + ( result ? 'しました。' : 'に失敗しました。')
        end
      end
    end
    redirect_to :action => 'manage', :menu => 'manage_permit'
  end

  # post_action
  # 更新
  def update
    if @group.update_attributes(params[:group])
      flash.now[:notice] = 'グループ情報は正しく更新されました。'
    end
    manage
  end

  # post_action
  # 削除
  def destroy
    if @group.group_participations.size > 1
      flash[:warning] = '自分以外のユーザがまだ存在しています。削除できません。'
      redirect_to :action => 'show'
    else
      @group.destroy
      flash[:notice] = 'グループは削除されました。'
      redirect_to :controller => 'groups'
    end
  end

  # ajax action
  # お気に入りのステータスを設定する
  def ado_set_favorite
    par_id = params[:group_participation_id]
    favorite_flag = params[:favorite_flag]
    participation = @group.group_participations.find(par_id)
    if participation.user_id != session[:user_id]
      render :nothing => true
      return false
    end
    participation.update_attribute(:favorite, favorite_flag)
    render :partial => "groups/favorite", :locals => { :gid => @group.gid, :participation => participation, :update_elem_id => params[:update_elem_id]}
  end

  # 参加者追加(管理者のみ)
  def append_user
    # 参加制約は追加しない。制約は制約管理で。
    symbol_type, symbol_id = Symbol.split_symbol params[:symbol]
    case symbol_type
    when 'uid'
      user = User.find_by_uid(symbol_id)
      if @group.group_participations.find_by_user_id(user.id)
        flash[:notice] = "#{user.name}さんは既に参加済み/参加申請済みです。"
      else
        @group.group_participations.build(:user_id => user.id, :owned => false)
        @group.save
        flash[:notice] = "#{user.name}さんを参加者に追加し、連絡の掲示板を作成しました。"
      end
    when 'gid'
      group = Group.find_by_gid(symbol_id, :include => :group_participations)
      group.group_participations.each do |participation|
        unless @group.group_participations.find_by_user_id(participation.user_id)
          @group.group_participations.build(:user_id => participation.user_id, :owned => false)
        end
      end
      @group.save
      flash[:notice] = "#{group.name}のメンバーを参加者に追加し、連絡の掲示板を作成しました。"
    else
      flash[:warning] = "ユーザ／グループの指定方法が間違っています"
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
    @tab_menu_source = tab_menu_source
    @tab_menu_option = tab_menu_option
  end

  def main_menu
    'グループ'
  end

  def title
    @group.name if @group
  end

  def tab_menu_source
    tab_menu_source = []
    tab_menu_source << {:label => _('サマリ'), :options => {:action => 'show'}}
    tab_menu_source << {:label => _('参加者一覧'), :options => {:action => 'users'}}
    tab_menu_source << {:label => _('掲示版'), :options => {:action => 'bbs'}}
    tab_menu_source << {:label => _('新規投稿'), :options => {:action => 'new'}} if participating?
    tab_menu_source << {:label => _('ファイル'), :options => {:action => 'share_file'}}
    tab_menu_source << {:label => _('管理'), :options => {:action => 'manage'}} if participating? and @participation.owned?
    tab_menu_source
  end

  def tab_menu_option
    { :gid => @group.gid }
  end

  def load_group_and_participation
    unless @group = Group.find_by_gid(params[:gid])
      flash[:warning] = "指定のグループは存在していません"
      redirect_to :controller => 'mypage', :action => 'index'
      return false
    end
    @participation = @group.group_participations.find_by_user_id(session[:user_id])
  end

  # TODO Group#participating?に順次置き換えていって最終的に削除する。
  def participating?
    @participation and @participation.waiting? != true
  end

  def check_owned
    unless @participation and @participation.owned?
      flash[:warning] = 'その操作は管理者権限が必要です。'
      redirect_to :controller => 'mypage', :action => 'index'
      return false
    end
  end


  def paginate_participations group, waiting
    return paginate(:group_participations,
                    :per_page => 20,
                    :conditions => ["group_participations.group_id = ? and group_participations.waiting = ?", group.id, waiting],
                    :include => :user)
  end

  def setup_bbs_left_box options
    find_params = BoardEntry.make_conditions(login_user_symbols, options)
    # 最近の投稿
    @recent_entries = BoardEntry.find(:all,
                                      :limit => 5,
                                      :conditions => find_params[:conditions],
                                      :include => find_params[:include],
                                      :order => "last_updated DESC,board_entries.id DESC")
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
