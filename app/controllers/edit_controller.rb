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

class EditController < ApplicationController
  include BoardEntriesHelper

  verify :method => :post, :only => [ :create, :update, :destroy, :delete_trackback ],
         :redirect_to => { :action => :index }

  # tab_menu
  def index
    params[:entry_type] = BoardEntry::DIARY if params[:entry_type].blank?
    owner = BoardEntry.owner(params[:symbol])
    owner ||= current_user
    params[:symbol] = owner.symbol

    params[:publication_type] = "public" if params[:publication_type].blank?
    params[:publication_symbols_value] = "" if params[:publication_symbols_value].blank?

    case params[:editor_mode] ||= current_user.custom.editor_mode
    when "richtext"
      params[:contents_richtext] = params[:contents]
    when "hiki"
      params[:contents_hiki] = params[:contents]
    end

    @board_entry = BoardEntry.new
    @board_entry.entry_type = params[:entry_type]
    @board_entry.symbol = params[:symbol]
    @board_entry.title = params[:title]
    @board_entry.category = params[:category]
    @board_entry.aim_type = params[:aim_type]
    if owner
      if owner.is_a?(Group)
        @board_entry.send_mail = (@board_entry.is_question? && SkipEmbedded::InitialSettings['mail']['default_send_mail_of_question']) || owner.default_send_mail
      elsif owner.is_a?(User)
        @board_entry.send_mail = @board_entry.is_question? && SkipEmbedded::InitialSettings['mail']['default_send_mail_of_question']
      end
    end

    setup_layout @board_entry
  end

  # post_action
  def create
    @board_entry = BoardEntry.new(params[:board_entry])

    case @board_entry.editor_mode = params[:editor_mode]
    when "hiki"
      @board_entry.contents = params[:contents_hiki]
    when "richtext"
      @board_entry.contents = params[:contents_richtext]
    end

    unless validate_params params, @board_entry
      @board_entry.send_mail = params[:board_entry][:send_mail] if params[:board_entry]
      flash[:warn] = _("Invalid parameter(s) found.")
      render :action => 'index'
      return
    end

    @board_entry.user_id  = current_user.id
    @board_entry.last_updated = Time.now
    @board_entry.publication_type = params[:publication_type]
    @board_entry.publication_symbols_value = params[:publication_type]=='protected' ? params[:publication_symbols_value] : ""

    # 権限チェック
    unless (session[:user_symbol] == params[:board_entry][:symbol]) ||
      current_user.group_symbols.include?(params[:board_entry][:symbol])

      redirect_to_with_deny_auth and return
    end

    if @board_entry.save
      target_symbols  = analyze_params(@board_entry)
      target_symbols.first.each do |target_symbol|
        @board_entry.entry_publications.create(:symbol => target_symbol)
      end
      target_symbols.last.each do |target_symbol|
        @board_entry.entry_editors.create(:symbol => target_symbol)
      end
      current_user.custom.update_attributes(:editor_mode => params[:editor_mode])

      message, new_trackbacks = @board_entry.send_trackbacks(current_user.belong_symbols, params[:trackbacks])
      make_trackback_message(new_trackbacks)

      @board_entry.send_contact_mails

      flash[:notice] = _('Created successfully.') + message
      redirect_to @board_entry.get_url_hash
    else
      setup_layout @board_entry
      render :action => 'index'
    end
  end

  # link_action
  def edit
    @board_entry = get_entry(params[:id])
    # 権限チェック
    redirect_to_with_deny_auth and return unless authorize_to_edit_board_entry? @board_entry

    params[:entry_type] ||= @board_entry.entry_type
    params[:symbol] ||= @board_entry.symbol

    params[:publication_type] = ""
    params[:publication_symbols_value] = ""

    params[:editor_symbols_value] = ""
    params[:editor_symbol] = false

    entry_trackbacks = EntryTrackback.find_all_by_tb_entry_id(@board_entry.id)
    params[:trackbacks] = entry_trackbacks.map{|trackback| trackback.board_entry_id }.join(',')

    if @board_entry.public?
      params[:publication_type] = "public"
      params[:publication_symbols_value] = ""
      params[:editor_symbols_value] = ""
      params[:editor_symbol]  = true if @board_entry.entry_editors.size == 1 && @board_entry.entry_editors.first.symbol == @board_entry.symbol
    elsif @board_entry.private?
        params[:publication_type] = "private"
        params[:editor_symbols_value] = ""
        params[:editor_symbol]  = true if @board_entry.entry_editors.size == 1 && @board_entry.entry_editors.first.symbol == @board_entry.symbol
    else
      params[:publication_type] = "protected"
      writer = User.find(@board_entry.user_id)
      params[:publication_symbols_value] = @board_entry.publication_symbols_value
      @board_entry.entry_editors.each do |editor|
        unless  editor.symbol == writer.symbol
          params[:editor_symbols_value] << editor.symbol
          params[:editor_symbols_value] << ","
        end
      end
      params[:editor_symbols_value] = params[:editor_symbols_value].chomp(',')
    end

    case params[:editor_mode] ||= @board_entry.editor_mode
    when "hiki"
      params[:contents_hiki] = @board_entry.contents
    when "richtext"
      params[:contents_richtext] = @board_entry.contents
    end

    setup_layout @board_entry
  end

  # post_acttion
  def update
    @board_entry = get_entry params[:id]
    #編集の競合をチェック
    @conflicted = false

    unless validate_params params, @board_entry
      @board_entry.send_mail = params[:board_entry][:send_mail] if params[:board_entry]
      flash.now[:warn] = _("Invalid parameter(s) found.")
      setup_layout @board_entry
      render :action => 'edit'
      return
    end

    update_params = params[:board_entry].dup

    case update_params[:editor_mode] = params[:editor_mode]
    when "hiki"
      update_params[:contents] = params[:contents_hiki]
    when "richtext"
      update_params[:contents] = params[:contents_richtext]
    end

    update_params[:publication_type] = params[:publication_type]
    update_params[:publication_symbols_value] = params[:publication_type]=='protected' ? params[:publication_symbols_value] : ""

    # 権限チェック
    redirect_to_with_deny_auth and return unless authorize_to_edit_board_entry? @board_entry

    # 成りすましての更新を防止
    if params[:board_entry][:symbol] != @board_entry.symbol
      redirect_to_with_deny_auth and return
    end

    # ちょっとした更新でなければ、last_updatedを更新する
    update_params[:last_updated] = Time.now unless params[:non_update]

    @board_entry.update_attributes!(update_params)
    @board_entry.entry_publications.clear
    @board_entry.entry_editors.clear
    target_symbols = analyze_params(@board_entry)
    target_symbols.first.each do |target_symbol|
      @board_entry.entry_publications.create(:symbol => target_symbol)
    end
    target_symbols.last.each do |target_symbol|
      @board_entry.entry_editors.create(:symbol => target_symbol)
    end
    current_user.custom.update_attributes(:editor_mode => params[:editor_mode])

    message, new_trackbacks = @board_entry.send_trackbacks(current_user.belong_symbols, params[:trackbacks])
    make_trackback_message(new_trackbacks)

    @board_entry.send_contact_mails

    flash[:notice] = _('Entry was successfully updated.') + message
    redirect_to @board_entry.get_url_hash
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    setup_layout @board_entry
    render :action => 'edit'
  rescue ActiveRecord::StaleObjectError => e
    @conflicted = true
    @board_entry.lock_version = @board_entry.lock_version_was
    flash.now[:warn] = _("Update on the same entry from other users detected. Reset the edit?")
    setup_layout @board_entry
    render :action => 'edit'
  end

  # post_action
  def destroy
    @board_entry = get_entry params[:id]

    # 権限チェック
    redirect_to_with_deny_auth and return unless authorize_to_edit_board_entry? @board_entry

    # FIXME [#855][#907]Rails2.3.2のバグでcounter_cacheと:dependent => destoryを併用すると常にStaleObjectErrorとなる
    # SKIPではBoardEntryとBoardEntryCommentの関係が該当する。Rails2.3.5でFixされたら以下を修正すること
    # 詳細は http://dev.openskip.org/redmine/issues/show/855
    @board_entry.board_entry_comments.destroy_all
    @board_entry.reload

    @board_entry.destroy
    flash[:notice] = _('Deletion complete.')
    # そのユーザのブログ一覧画面に遷移する
    # TODO: この部分をメソッド化した方がいいかも(by mat_aki)
    redirect_to @board_entry.get_url_hash.delete_if{|key,val| key == :entry_id}
  rescue ActiveRecord::StaleObjectError => e
    flash[:warn] = _("Update on the same entry from other users detected. Please try again.")
    setup_layout @board_entry
    redirect_to url_for(:action => 'edit', :id => @board_entry)
  end

  def delete_trackback
    @board_entry = get_entry params[:id]

    redirect_to_with_deny_auth and return unless @board_entry.user_id == session[:user_id]

    tb_entries = EntryTrackback.find_all_by_board_entry_id_and_tb_entry_id(@board_entry.id, params[:tb_entry_id])
    tb_entries.each do |tb_entry|
      tb_entry.destroy
    end

    flash[:notice] = _("Specified trackback was deleted successfully.")
    redirect_to @board_entry.get_url_hash
  end

  # ajax_action
  def ado_preview
    board_entry = BoardEntry.new(params[:board_entry])
    board_entry.contents = params[:contents_hiki]
    board_entry.id = params[:id]
    board_entry.user_id = session[:user_id]
    render :partial=>'board_entries/board_entry_box', :locals=>{:board_entry=>board_entry}
  end

private
  def setup_layout board_entry
    board_entry.load_owner unless board_entry.owner
    @main_menu = board_entry.owner.is_a?(Group) ? _('Groups') : _('My Blog')
    @title = board_entry.owner.name
  end

  def analyze_params board_entry
    target_symbols_publication = []
    target_symbols_editor = []
    case params[:publication_type]
    when "public"
      target_symbols_publication << "sid:allusers"
      target_symbols_editor  << params[:editor_symbol] if (params[:entry_type] != 'DIARY' && params[:editor_symbol])
    when "private"
      target_symbols_publication << params[:board_entry][:symbol] unless params[:entry_type] == 'DIARY'
      target_symbols_editor  << params[:editor_symbol] if (params[:entry_type] != 'DIARY' && params[:editor_symbol])
      target_symbols_publication << User.find(board_entry.user_id).symbol
    when "protected"
      target_symbols_publication = params[:publication_symbols_value].split(/,/).map {|symbol| symbol.strip }
      target_symbols_editor = params[:editor_symbols_value].split(/,/).map {|symbol| symbol.strip }
      target_symbols_publication << User.find(board_entry.user_id).symbol
    else
      raise _("Invalid parameter(s).")
    end
    return target_symbols_publication, target_symbols_editor
  end

  # 独自のバリデーション（成功ならtrue）
  # TODO チェックをモデルに寄せたい
  def validate_params params, entry
    # 公開範囲のタイプ
    unless %w(public private protected).include? params[:publication_type]
      entry.errors.add_to_base _("Invalid privacy setting.")
    end
    # 公開範囲の値
    if params[:publication_type] == "protected" && params[:publication_symbols_value]
      unless params[:publication_symbols_value].empty?
        unless /\A[\s]*((u|g|e)id:[^,]*,)*[\s]*(u|g|e)id[^,]*\Z/ =~ params[:publication_symbols_value]
          entry.errors.add_to_base _("Invalid privacy setting.")
        end
      end
    end
    # 公開日付
    unless Date.valid_date?(*params[:board_entry].values_at('date(1i)', 'date(2i)', 'date(3i)').map(&:to_i))
      entry.errors.add(:date, _("needs to be a valid date."))
    end
    entry.errors.empty?
  end

  def make_trackback_message(new_trackbacks)
    new_trackbacks.each do |trackback|
      next if trackback.board_entry.user_id == session[:user_id]
      board_entry = trackback.board_entry
      SystemMessage.create_message :message_type => 'TRACKBACK', :user_id => board_entry.user_id, :message_hash => {:board_entry_id => board_entry.id}
    end
  end

  def authorize_to_edit_board_entry? entry
    entry.editable?(current_user.belong_symbols, session[:user_id], session[:user_symbol], current_user.group_symbols)
  end

  def get_entry entry_id
    @board_entry = BoardEntry.find(params[:id])
  end

end

