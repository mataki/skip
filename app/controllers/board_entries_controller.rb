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

  verify :method => :post, :only => [ :toggle_hide  ],
         :redirect_to => { :action => :index, :controller => "/mypage" }

  before_filter :owner_required, :only => %w(edit update destroy)
  before_filter :required_full_accessible_entry, :only => %w(edit update destroy)
  before_filter :required_accessible_entry, :only => %w(show print)
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
    unless current_target_owner
      @current_target_owner = current_target_entry.owner
    end
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

  # 印刷表示
  def print
    respond_to do |format|
      format.html { render :layout => false }
    end
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
  def setup_layout board_entry
    @main_menu = board_entry.owner.is_a?(Group) ? _('Groups') : _('My Blog')
    @title = board_entry.owner.name
  end
end
