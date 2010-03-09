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

class ShareFilesController < ApplicationController
  include IframeUploader
  include UsersHelper
  include EmbedHelper

  before_filter :owner_required, :only => [:show, :edit, :update, :destroy]
  before_filter :required_full_accessible, :only => [:edit, :update, :destroy, :download_history_as_csv, :clear_download_history]
  before_filter :required_accessible, :only => [:show]

  def index
    @main_menu = @title = _('Files')
    params[:tag_select] ||= "AND"
    params[:sort_type] ||= "date"

    @search = ShareFile.accessible(current_user).tagged(params[:tag_words], params[:tag_select])
    search_params = params[:search] || {}
    if current_target_owner
      search_params[:owner_type] = current_target_owner.class.name
      search_params[:owner_id] = current_target_owner.id
    end
    @search =
      if params[:sort_type] == "file_name"
        @search.descend_by_file_name.search(search_params)
      else
        @search.descend_by_date.search(search_params)
      end
    @share_files = @search.paginate(:page => params[:page], :per_page => 25)

    respond_to do |format|
      format.html do
        @tags = ShareFile.get_popular_tag_words
        if @share_files.empty?
          flash.now[:notice] = _('No matching data found.')
        end
        render
      end
    end
  end

  def show
    unless downloadable?(params[:authenticity_token], current_target_share_file)
      respond_to do |format|
        format.html do
          @main_menu = @title = _('File Download')
          render :action => 'confirm_download'
          return
        end
      end
    end

    # TODO current_target_share_fileに統合してもいいかもしれない。
    unless File.exist?(current_target_share_file.full_path)
      flash[:warn] = _('Could not find the entity of the specified file. Contact system administrator.')
      respond_to do |format|
        format.html do
          redirect_to [current_tenant, current_target_owner, :share_files]
          return
        end
      end
    end

    current_target_share_file.create_history current_user.id
    respond_to do |format|
      format.html do
        # TODO inlineパラメタの有無でdisposition切り替えは微妙か? アクション分ける? 拡張子やContentTypeで自動判別する? 検討する。
        send_file(
          current_target_share_file.full_path, 
          :filename => nkf_file_name(current_target_share_file.file_name),
          :type => current_target_share_file.content_type || Types::ContentType::DEFAULT_CONTENT_TYPE,
          :stream => false,
          :disposition => params[:inline] ? 'inline' : 'attachment')
      end
    end
  end

  def new
    @share_file = current_target_owner.owner_share_files.build(params[:share_file])
    required_full_accessible(@share_file) do
      respond_to do |format|
        format.html do
          ajax_upload? ? render(:template => 'share_files/new_ajax_upload', :layout => false) : render
        end
      end
    end
  end

  # post action
  def create
    @share_file = current_target_owner.owner_share_files.build(params[:share_file])

    required_full_accessible(@share_file) do
#      # TODO modelに持っていけないか?(validate_on_createあたり)
#      unless @share_file.file
#        respond_to do |format|
#          format.html do
#            ajax_upload? ? render(:text => {:status => '400', :messages => [_("%{name} is mandatory.") % { :name => _('File') }]}.to_json) : render :action => :new
#            return
#          end
#        end
#      end
      @share_file.user = current_user
      @share_file.tenant = current_tenant
      ShareFile.transaction do
        @share_file.save!
        respond_to do |format|
          format.html do
            flash[:notice] = _('File was successfully uploaded.')
            if ajax_upload?
              render(:text => {:status => '200', :messages => [notice_message]}.to_json)
            else
              redirect_to [current_tenant, current_target_owner, :share_files]
            end
          end
        end
      end
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    respond_to do |format|
      format.html do
        ajax_upload? ? render(:text => {:status => '400', :messages => @error_messages}.to_json) : render(:action => "new")
      end
    end
  end

  def edit
  end

  def update
    if @share_file.update_attributes(params[:share_file])
      respond_to do |format|
        format.html do
          flash[:notice] = _('Updated.')
          redirect_to [current_tenant, current_target_owner, :share_files]
        end
      end
    else
      respond_to do |format|
        format.html do
          render :action => :edit
        end
      end
    end
  end

  def destroy
    @share_file.destroy
    respond_to do |format|
      format.html do
        flash[:notice] = _("File was successfully deleted.")
        redirect_to [current_tenant, current_target_owner, :share_files]
      end
    end
  end

  # TODO 以下はindexに統合して消す
#  def list
#    # TODO: インスタンス変数の数を減らす
#    owner = current_target_user || current_target_group
#    unless owner
#      flash[:warn] = _("Specified share file owner does not exist.")
#      redirect_to root_url
#      return
#    end
#
#    @search = ShareFile.accessible(current_user).owned(owner)
#    @search = @search.tagged(params[:category], "AND") if params[:category]
#    @search =
#      if params[:sort_type] == "file_name"
#        @search.descend_by_file_name.search(params[:search])
#      else
#        @search.descend_by_date.search(params[:search])
#      end
#    @share_files = @search.paginate(:page => params[:page], :per_page => 10)
#
#    respond_to do |format|
#      format.html do
#        if owner.is_a? User
#          @main_menu = user_main_menu(owner)
#          @title = user_title(owner)
#          @tab_menu_option = user_menu_option(owner)
#        elsif owner.is_a? Group
#          @main_menu = _('Groups')
#          @title = owner.name
#          @tab_menu_option = { :gid => owner.gid }
#        end
#        @owner_name = owner.name
#        params[:sort_type] ||= "date"
#        flash.now[:notice] = _('No matching shared files found.') if @share_files.empty?
#        render :layout => 'layout'
#      end
#      format.js {
#        render :json => {
#          :pages => {
#            :first => 1,
#            :previous => @share_files.previous_page,
#            :next => @share_files.next_page,
#            :last => @share_files.total_pages,
#            :current => @share_files.current_page,
#            :item_count => @share_files.total_entries },
#          :share_files => @share_files.map{|s| share_file_to_json(s) }
#        }
#      }
#    end
#  end

#  def download
#    symbol_type_hash = { 'user'  => 'uid',
#                         'group' => 'gid' }
#    file_name =  params[:file_name]
#    owner_symbol = "#{symbol_type_hash[params[:controller_name]]}:#{params[:symbol_id]}"
#
#    unless share_file = ShareFile.find_by_file_name_and_owner_symbol(file_name, owner_symbol)
#      raise ActiveRecord::RecordNotFound
#    end
#
#    unless share_file.readable?(current_user)
#      redirect_to_with_deny_auth
#      return
#    end
#
#    if downloadable?(params[:authenticity_token], share_file)
#      unless File.exist?(share_file.full_path)
#        flash[:warn] = _('Could not find the entity of the specified file. Contact system administrator.')
#        return redirect_to(:controller => 'mypage', :action => "index")
#      end
#
#      share_file.create_history current_user.id
#      # TODO inlineパラメタの有無でdisposition切り替えは微妙か? アクション分ける? 拡張子やContentTypeで自動判別する? 検討する。
#      send_file(share_file.full_path, :filename => nkf_file_name(file_name), :type => share_file.content_type || Types::ContentType::DEFAULT_CONTENT_TYPE, :stream => false, :disposition => params[:inline] ? 'inline' : 'attachment')
#    else
#      @main_menu = @title = _('File Download')
#      render :action => 'confirm_download', :layout => 'layout'
#    end
#  end

  def downloadable?(authenticity_token, share_file)
    return true if share_file.uncheck_authenticity?
    authenticity_token == form_authenticity_token ? true : false
  end

  def download_history_as_csv
    csv_text, file_name = @share_file.get_accesses_as_csv
    send_data(csv_text, :filename => nkf_file_name(file_name), :type => 'application/x-csv', :disposition => 'attachment')
  end

  def clear_download_history
    # FIXME share_file#total_countが0になってない
    @share_file.share_file_accesses.delete_all
    respond_to do |format|
      format.html do
        flash[:notice] = _('Download history was successfully deleted.')
        redirect_to [current_tenant, current_target_owner, :share_files]
      end
    end
  end

private
  def nkf_file_name(file_name)
    agent = request.headers['HTTP_USER_AGENT']
    (agent.include?("MSIE") and not agent.include?("Opera")) ? NKF.nkf('-Ws', file_name) : file_name
  end

  def share_file_to_json(share_file)
    returning(share_file.attributes) do |json|
      src = share_file_url(:controller_name => share_file.owner_symbol_type, :symbol_id => share_file.owner_symbol_id, :file_name => share_file.file_name)
      if share_file.image_extention?
        json[:src] = "#{src}?#{share_file.updated_at.to_i.to_s}"
        json[:file_type] = 'image'
      else
        json[:src] = src
        json[:file_type] = share_file.extname
      end
      json[:insert_tag] =
        if share_file.image_extention?
          # TODO 後で
        elsif share_file.extname == 'flv'
          flv_tag json[:src] + '?inline=true'
        elsif share_file.extname == 'swf'
          swf_tag json[:src] + '?inline=true'
        else
          # TODO 後で
        end
    end
  end

  def current_target_share_file
    @share_file ||= ShareFile.find(params[:id])
  end

  def required_full_accessible share_file = current_target_share_file
    if result = share_file.full_accessible?(current_user)
      yield if block_given?
    else
      redirect_to_with_deny_auth
    end
    result
  end

  def required_accessible share_file = current_target_share_file
    if result = share_file.accessible?(current_user)
      yield if block_given?
    else
      redirect_to_with_deny_auth
    end
    result
  end
end
