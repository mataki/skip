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

class UserController < ApplicationController
  helper 'board_entries', 'groups'

  before_filter :load_user, :setup_layout
  after_filter :make_chain_message, :only => [ :create_chain, :update_chain ]

  verify :method => :post, :only => [ :create_chain, :update_chain ],
         :redirect_to => { :action => :index }

  # tab_menu
  def show
    limit = 5

    # 参加しているグループ一覧
    conditions = ["group_participations.user_id = ?", @user.id]
    @groups = Group.find(:all, :limit => limit,
                         :conditions => conditions,
                         :order => "group_participations.created_on DESC",
                         :include => :group_participations)
    @groups_count = Group.count(:conditions => conditions,
                                :include => :group_participations)

    # 紹介した人一覧
    @follow_chains =  Chain.find(:all, :limit => limit,
                                 :order => "updated_on DESC",
                                 :conditions => ['from_user_id = ?', @user.id])
    # 紹介してくれた人一覧
    @against_chains = Chain.find(:all, :limit => limit,
                                 :order => "updated_on DESC",
                                 :conditions => ['to_user_id = ?', @user.id])
    # 他の人からみた・・・
    @tags = BookmarkComment.get_tagcloud_tags @user.get_postit_url
  end

  # tab_menu
  def blog
    @main_menu = 'マイページ' if @user.id == session[:user_id]

    options = { :symbol => "uid:" + @user.uid }
    setup_blog_left_box options
    order = "last_updated DESC , board_entries.id DESC"

    # 右側
    if params[:category] or params[:keyword] or params[:archive]
      options[:category] = params[:category]
      options[:keyword] = params[:keyword]

      params[:sort_type] ||= "date"
      if params[:sort_type] == "access"
        order = "board_entry_points.access_count DESC"
      end

      find_params = BoardEntry.make_conditions(login_user_symbols, options)

      unless (@year = ERB::Util.html_escape(params[:year])).blank? or (@month = ERB::Util.html_escape(params[:month])).blank?
        find_params[:conditions][0] << " and YEAR(date) = ? and MONTH(date) = ?"
        find_params[:conditions] << @year << @month
      end

      @pages, @entries = paginate(:board_entries,
                                  :per_page => 20,
                                  :order => order,
                                  :conditions => find_params[:conditions],
                                  :include => find_params[:include] | [ :user, :board_entry_comments, :state ])
      unless @entries && @entries.size > 0
        flash.now[:notice] = '該当する投稿はありませんでした。'
      end
    else
      if entry_id = params[:entry_id]
        unless entry = BoardEntry.find_by_id(entry_id)
          flash.now[:notice] = '現在投稿がありません。'
          return
        end
        options[:id] = entry_id
      end
      find_params = BoardEntry.make_conditions(login_user_symbols, options)
      @entry = BoardEntry.find(:first,
                               :order => order,
                               :conditions => find_params[:conditions],
                               :include => find_params[:include] | [ :user, :board_entry_comments, :state ])
      if @entry
        login_user_id = session[:user_id]
        @entry.accessed(login_user_id)
        @prev_entry, @next_entry = @entry.get_around_entry(login_user_symbols)
        @editable = @entry.editable?(login_user_symbols, session[:user_id], session[:user_symbol], login_user_groups)
        @tb_entries = @entry.trackback_entries(login_user_id, login_user_symbols)
        @to_tb_entries = @entry.to_trackback_entries(login_user_id, login_user_symbols)
        @title += " - " + @entry.title

        @entry_accesses =  EntryAccess.find_by_entry_id @entry.id
        @total_count = @entry.state.access_count
        bookmark = Bookmark.find(:first, :conditions =>["url = ?", "/page/"+@entry.id.to_s])
        @bookmark_comments_count = bookmark ? bookmark.bookmark_comments_count : 0
      else
        flash.now[:notice] = options[:id] ? '閲覧権限がありません。' : '現在投稿がありません。'
      end
    end
  end

  # tab_menu
  def social
    @menu = params[:menu] || "social_chain"
    partial_name = @menu

    # contents_left -> social_tags
    @tags = BookmarkComment.get_tagcloud_tags @user.get_postit_url

    # contens_right
    case @menu
    when "social_chain"
      prepare_chain
    when "social_chain_against"
      prepare_chain true
      partial_name = "social_chain"
    when "social_postit"
      prepare_postit
    end

    render :partial => partial_name, :layout => "layout"
  end

  # tab_menu
  def bookmark
    @main_menu = 'マイページ' if @user.id == current_user.id

    params[:user_id] = @user.id
    text = render_component_as_string( :controller => 'bookmark', :action => 'list', :id => @user.symbol, :params => params)
    render :text => text, :layout => false
  end

  # tab_menu
  def group
    params[:user_id] = @user.id
    params[:group_category_id] ||= "all"
    params[:sort_type] ||= "date"
    params[:participation] = true
    @format_type = params[:format_type] ||= "list"
    @group_counts, @total_count = Group.count_by_category(@user.id)
    @group_categories = GroupCategory.all

    @show_favorite = (@user.id == session[:user_id])

    options = Group.paginate_option(@user.id, params)
    options[:per_page] = params[:format_type] == "list" ? 30 : 5
    @pages, @groups = paginate(:group, options)

    flash.now[:notice] = '該当するグループはありませんでした。' unless @groups && @groups.size > 0
  end

  # tab_menu
  def new_chain
    @chain = Chain.new
    show_new_chain
  end

  # tab_menu
  def edit_chain
    @chain = Chain.find_by_from_user_id_and_to_user_id(session[:user_id], @user.id)
    show_edit_chain
  end

  # tab_menu
  def share_file
    @main_menu = 'マイページ' if @user.id == session[:user_id]

    params.store(:owner_name, @user.name)
    params.store(:visitor_is_uploader, (@user.id == session[:user_id]))
    text = render_component_as_string :controller => 'share_file', :action => 'list', :id => @user.symbol, :params => params
    render :text => text, :layout => false
  end

  # post_action
  def create_chain
    @chain = Chain.new( :from_user_id => session[:user_id],
                        :to_user_id => @user.id,
                        :comment => params[:chain][:comment])
    if @chain.save
      flash[:notice] = '紹介文を作成しました'
      redirect_to_index
    else
      show_new_chain
    end
  end

  # post_action
  def update_chain
    @chain = Chain.find_by_from_user_id_and_to_user_id(session[:user_id], @user.id)

    if params[:chain][:comment].empty?
      @chain.destroy
      @chain = nil
      flash[:notice] = '紹介文を削除しました'
      redirect_to_index
    elsif @chain.update_attributes(params[:chain])
      flash[:notice] = '紹介文を更新しました'
      redirect_to_index
    else
      show_edit_chain
    end
  end

private
  def setup_layout
    @title = title
    @main_menu = main_menu
    @tab_menu_source = tab_menu_source
    @tab_menu_option = tab_menu_option
  end

  def main_menu
    @user.id == current_user.id ? 'マイページ' : 'ユーザ'
  end

  def title
    @user.id == current_user.id ? 'マイページ' : "#{@user.name}さん"
  end

  def tab_menu_source
    tab_menu_source = [
      {:label => _('プロフィール'), :options => {:action => 'show'}},
      {:label => _('ブログ'), :options => {:action => 'blog'}},
      {:label => _('ファイル'), :options => {:action => 'share_file'}},
      {:label => _('ソーシャル'), :options => {:action => 'social'}},
      {:label => _('グループ'), :options => {:action => 'group'}},
      {:label => _('ブックマーク'), :options => {:action => 'bookmark'}} ]

    if @user.id != current_user.id
      if Chain.count(:conditions => ["from_user_id = ? and to_user_id = ?", current_user.id, @user.id]) <= 0
        tab_menu_source << {:label => _('紹介文を作る'), :options => {:action => 'new_chain'}}
      else
        tab_menu_source << {:label => _('紹介文の変更'), :options => {:action => 'edit_chain'}}
      end
    else
      tab_menu_source.unshift({:label => _('ホーム'), :options => {:action => 'index'}, :selected_actions => %w(index entries entries_by_date entries_by_antenna)}) 
      tab_menu_source << {:label => _('足跡'), :options => {:action => 'trace'}}
      tab_menu_source << {:label => _('管理'), :options => {:action => 'manage'}}
    end
    tab_menu_source
  end

  def tab_menu_option
    { :uid => @user.uid }
  end

  def load_user
    if @user = User.find_by_uid(params[:uid])
      @user.mark_track session[:user_id] if @user.id != session[:user_id]
    else
      flash[:warning] = _('ご指定のユーザは存在しません。')
      redirect_to :controller => 'mypage', :action => 'index'
      return false
    end

    if @user.id == session[:user_id] and %(index, trace, manage).include?(self.action_name)
      redirect_to :controller => 'mypage', :action => self.action_name
      return false
    end
  end

  def redirect_to_index
    redirect_to :action => 'show', :uid => @user.uid
  end

  def show_new_chain
    @submit_action = 'create_chain'
    @submit_name = '作成'
    render :action=>'new_edit_chain'
  end

  def show_edit_chain
    @submit_action = 'update_chain'
    @submit_name = '更新'
    render :action=>'new_edit_chain'
  end

  def setup_blog_left_box options
    find_params = BoardEntry.make_conditions(login_user_symbols, options)
    # 最近の投稿
    @recent_entries = BoardEntry.find(:all,
                                      :limit => 5,
                                      :conditions => find_params[:conditions],
                                      :include => find_params[:include],
                                      :order => "last_updated DESC ,board_entries.id DESC")
    # カテゴリ
    @categories = BoardEntry.get_category_words(find_params)

    # 月毎のアーカイブ
    @month_archives = BoardEntry.find(:all,
                                      :select => "YEAR(date) as year, MONTH(date) as month, count(distinct board_entries.id) as count",
                                      :conditions=> find_params[:conditions],
                                      :group => "year, month",
                                      :order => "year desc, month desc",
                                      :joins => "LEFT OUTER JOIN entry_publications ON entry_publications.board_entry_id = board_entries.id")
  end

  def make_chain_message
    return unless @chain
    link_url = url_for(:controller => 'user', :uid => @user.uid, :action => 'social', :menu => 'social_chain' , :only_path => true)
    Message.save_message("CHAIN", @user.id, link_url)
  end

  def prepare_chain against = false
    unless against
      left_key, right_key = "to_user_id", "from_user_id"
    else
      left_key, right_key = "from_user_id", "to_user_id"
    end

    @pages, chains = paginate(:chains,
                              :per_page => 5,
                              :conditions => [left_key + " = ?", @user.id],
                              :order_by => "updated_on DESC")

    user_ids = chains.inject([]) {|result, chain| result << chain.send(right_key) }
    against_chains = Chain.find(:all, :conditions =>[left_key + " in (?) and " + right_key + " = ?", user_ids, @user.id]) if user_ids.size > 0
    against_chains ||= []
    messages = against_chains.inject({}) {|result, chain| result ||= {}; result[chain.send(left_key)] = chain.comment; result }

    @result = []
    chains.each do |chain|
      @result << { :from_user => chain.from_user,
        :from_message => chain.comment,
        :to_user => chain.to_user,
        :counter_message => messages[chain.send(right_key)] || ""
      }
    end

    unless @pages && @pages.item_count > 0
      flash.now[:notice] = '現在紹介文はありません。'
    end
  end

  def prepare_postit
    join_state =  "left join bookmark_comment_tags on bookmark_comments.id = bookmark_comment_tags.bookmark_comment_id "
    join_state << "left join tags on tags.id = bookmark_comment_tags.tag_id "

    conditions = []
    conditions[0] = "bookmarks.url = ? "
    conditions << @user.get_postit_url
    if params[:selected_tag]
      conditions[0] << " and tags.name = ?"
      conditions << params[:selected_tag]
    end
    @postits = BookmarkComment.find(:all,
                                    :conditions => conditions,
                                    :order => "bookmark_comments.updated_on DESC",
                                    :joins => join_state,
                                    :include => [ :bookmark, :user ])
    unless @postits && @postits.size > 0
      flash.now[:notice] = '現在ブックマークはありません。'
    end
  end

end
