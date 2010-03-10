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

class BoardEntriesController < ApplicationController
  include AccessibleBoardEntry

  verify :method => :post, :only => [ :ado_create_nest_comment, :destroy_comment, :ado_edit_comment, :toggle_hide  ],
         :redirect_to => { :action => :index, :controller => "/mypage" }

  before_filter :owner_required, :only => [:show, :edit, :update, :destroy]
  before_filter :required_full_accessible_entry, :only => [:edit, :update, :destroy]
  before_filter :required_accessible_entry, :only => [:show, :large]
  after_filter :make_comment_message, :only => [ :ado_create_nest_comment ]
  after_filter :remove_system_message, :only => %w(show)

  def index
    @main_menu = @title = _('Entries')
    params[:tag_select] ||= "AND"

    search_params = params[:search] || {}
    if current_target_owner
      search_params[:owner_type] = current_target_owner.class.name
      search_params[:owner_id] = current_target_owner.id
    end
    @search = BoardEntry.accessible(current_user).tagged(params[:tag_words], params[:tag_select]).search(search_params)

    @entries = @search.paginate(:page => params[:page], :per_page => 25)

    respond_to do |format|
      format.html do
        @tags = BoardEntry.get_popular_tag_words
        if @entries.empty?
          flash.now[:notice] = _('No matching data found.')
        end
        render
      end
    end
  end

  def show
  end

  def new
    @board_entry = current_target_owner.owner_entries.build(params[:board_entry])
    required_full_accessible_entry(@board_entry) do
      @board_entry.entry_type = @board_entry.owner.is_a?(User) ? BoardEntry::DIARY : BoardEntry::GROUP_BBS
      @board_entry.publication_type ||= 'public'
      @board_entry.editor_mode ||= current_user.custom.editor_mode
      if @board_entry.owner.is_a?(Group)
        @board_entry.send_mail = (@board_entry.is_question? && SkipEmbedded::InitialSettings['mail']['default_send_mail_of_question']) || owner.default_send_mail
      elsif @board_entry.owner.is_a?(User)
        @board_entry.send_mail = @board_entry.is_question? && SkipEmbedded::InitialSettings['mail']['default_send_mail_of_question']
      end

      setup_layout @board_entry

      respond_to do |format|
        format.html
      end
    end
  end

  def edit
    entry_trackbacks = EntryTrackback.find_all_by_tb_entry_id(current_target_entry.id)
    params[:trackbacks] = entry_trackbacks.map{|trackback| trackback.board_entry_id }.join(',')
    if current_target_entry.hiki?
      current_target_entry.contents_hiki = current_target_entry.contents
    else
      current_target_entry.contents_richtext = current_target_entry.contents
    end
    setup_layout current_target_entry
    respond_to do |format|
      format.html
    end
  end

  def create
    @board_entry = current_target_owner.owner_entries.build(params[:board_entry])
    required_full_accessible_entry(@board_entry) do
      @board_entry.contents = @board_entry.hiki? ? @board_entry.contents_hiki : @board_entry.contents_richtext
      @board_entry.user = current_user
      @board_entry.tenant = current_tenant
      @board_entry.last_updated = Time.now
      BoardEntry.transaction do
        @board_entry.save!
        current_user.custom.update_attributes!(:editor_mode => @board_entry.editor_mode)
        @board_entry.send_trackbacks!(current_user, params[:trackbacks])
        @board_entry.send_contact_mails
        respond_to do |format|
          format.html do
            flash[:notice] = _('Created successfully.')
            redirect_to [current_tenant, current_target_owner, @board_entry]
          end
        end
      end
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    respond_to do |format|
      format.html { render :action => :new }
    end
  end

  def update
    @board_entry.attributes = params[:board_entry]
    @board_entry.contents = @board_entry.hiki? ? @board_entry.contents_hiki : @board_entry.contents_richtext
    #編集の競合をチェック
    @conflicted = false

    # ちょっとした更新でなければ、last_updatedを更新する
    if params[:non_update]
      BoardEntry.record_timestamps = false
    else
      @board_entry.last_updated = Time.now
    end
    BoardEntry.transaction do
      @board_entry.save!
      current_user.custom.update_attributes!(:editor_mode => @board_entry.editor_mode)
      @board_entry.send_trackbacks!(current_user, params[:trackbacks])
      @board_entry.send_contact_mails
      respond_to do |format|
        format.html do
          flash[:notice] = _('Entry was successfully updated.')
          redirect_to [current_tenant, current_target_owner, @board_entry]
        end
      end
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    respond_to do |format|
      format.html { render :action => :edit }
    end
  rescue ActiveRecord::StaleObjectError => e
    @conflicted = true
    @board_entry.lock_version = @board_entry.lock_version_was
    flash.now[:warn] = _("Update on the same entry from other users detected. Reset the edit?")
    respond_to do |format|
      format.html { render :action => :edit }
    end
  ensure
    BoardEntry.record_timestamps = true
  end

  def destroy
    @board_entry.destroy
    respond_to do |format|
      format.html do
        flash[:notice] = _('Deletion complete.')
        redirect_to [current_tenant, current_target_owner, :board_entries]
      end
    end
  rescue ActiveRecord::StaleObjectError => e
    flash[:warn] = _("Update on the same entry from other users detected. Please try again.")
    respond_to do |format|
      format.html do
        redirect_to [current_tenant, current_target_owner, @board_entry]
      end
    end
  end

  def ado_preview
    board_entry = BoardEntry.new(params[:board_entry])
    board_entry.user = current_user
    board_entry.contents = board_entry.contents_hiki
    render :partial=>'board_entries/board_entry_box', :locals=>{:board_entry => board_entry}
  end

  # 巨大化表示
  def large
    render :layout => false
  end

  # ネストコメントの作成
  def ado_create_nest_comment
    begin
      parent_comment = BoardEntryComment.find(params[:id])
    rescue ActiveRecord::RecordNotFound => ex
      render(:text => _('Parent comment could not be found. Try reloading the page.'), :status => :not_found) and return
    end

    if params[:contents].blank?
      render(:text => _('Comment body is mandatory.'), :status => :bad_request) and return
    end

    # TODO 権限のあるBoardEntryを取得するnamed_scopeに置き換える
    @board_entry = parent_comment.board_entry
    find_params = BoardEntry.make_conditions(current_user.belong_symbols, {:id => @board_entry.id})
    unless @board_entry = BoardEntry.find(:first,
                                          :conditions => find_params[:conditions],
                                          :include => find_params[:include] | [ :user, :board_entry_comments, :state ])
      render(:text => _('Target %{target} inexistent.')%{:target => _('board entry')}, :status => :bad_request) and return
    end

    comment = parent_comment.children.create(:board_entry_id => parent_comment.board_entry_id,
                                             :contents => params["contents"],
                                             :user_id => session[:user_id])
    unless comment.errors.empty?
      render(:text => _('Failed to save the data.'), :status => :bad_request) and return
    end
    render :partial => "board_entry_comment", :locals => { :comment => parent_comment.children.last, :level => params[:level].to_i }
  end

  def destroy_comment
    @board_entry_comment = BoardEntryComment.find(params[:id])
    board_entry = @board_entry_comment.board_entry

    # 権限チェック
    authorize = false
    authorize = true if session[:user_symbol] == board_entry.symbol

    if current_user.group_symbols.include?(board_entry.symbol)
      if current_user.group_symbols.include?(board_entry.user_id)
        authorize = true
      elsif board_entry.publicate?(current_user.belong_symbols)
        authorize = true
      end
    else
      if session[:user_id] == @board_entry_comment.user_id && board_entry.publicate?(current_user.belong_symbols)
        authorize = true
      end
    end

    redirect_to_with_deny_auth and return unless authorize

    if @board_entry_comment.children.size == 0
      @board_entry_comment.destroy
      flash[:notice] = _("Comment was successfully deleted.")
    else
      flash[:warn] = _("This comment cannot be deleted since it has been commented.")
    end
    redirect_to :action => "forward", :id => @board_entry_comment.board_entry.id
  rescue ActiveRecord::RecordNotFound => ex
    flash[:warn] = _("Comment seems have already deleted.")
    redirect_to :controller => "mypage", :action => "index"
  end

  # ajax_action
  def ado_edit_comment
    begin
      comment = BoardEntryComment.find(params[:id])
    rescue ActiveRecord::RecordNotFound => ex
      render(:text => _('Target %{target} inexistent.')%{:target => _('board entry comment')}, :status => :bad_request) and return
    end
    unless comment.editable? current_user
      render(:text => _('Operation unauthorized.'), :status => :bad_request) and return
    end

    comment.update_attribute :contents, params[:comment][:contents]
    render :partial => "comment_contents", :locals =>{ :comment => comment }
  end

  def forward
    begin
      entry = BoardEntry.find(params[:id])
    rescue ActiveRecord::RecordNotFound => ex
      flash[:warn] = _("Specified page does not exist.")
      redirect_to :controller => 'mypage', :action => ''
      return false
    end

    forward_hash = { 'uid' => { :controller => 'user',  :id =>"blog" },
                     'gid' => { :controller => 'group', :id =>'bbs'  } }

    flash.keep(:notice)
    flash.keep(:warn)
    redirect_to :controller => forward_hash[entry.symbol_type][:controller],
                :action     => entry.symbol_id,
                :id         => forward_hash[entry.symbol_type][:id],
                :entry_id   => entry.id
  end

  def toggle_hide
    @board_entry = BoardEntry.accessible(current_user).find params[:id]
    if @board_entry.toggle_hide(current_user)
      render :text => _("Entry was successfully set to %{operation}.") % { :operation => _("BoardEntry|Open|#{!@board_entry.hide}") }
    else
      render :text => _('Failed to update status.') + " : " + @board_entry.errors.full_messages.to_s, :status => :bad_request
    end
  end

private
  def make_comment_message
    return unless @board_entry
    unless @board_entry.writer?(session[:user_id])
      SystemMessage.create_message :message_type => 'COMMENT', :user_id => @board_entry.user.id, :message_hash => {:board_entry_id => @board_entry.id}
    end
  end

  def setup_layout board_entry
    @main_menu = board_entry.owner.is_a?(Group) ? _('Groups') : _('My Blog')
    @title = board_entry.owner.name
  end
end
