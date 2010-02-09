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

class ShareFileController < ApplicationController
  include IframeUploader
  include UserHelper
  include EmbedHelper
  layout 'subwindow'

  verify :method => :post, :only => [ :create, :update, :destroy, :download_history_as_csv, :clear_download_history ],
         :redirect_to => { :action => :index }

  def new
    owner = Symbol.get_item_by_symbol params[:owner_symbol]
    unless owner
      render_404 and return
    end
    @share_file = ShareFile.new(:user_id => current_user.id, :owner_symbol => owner.symbol)

    unless @share_file.updatable?(current_user)
      ajax_upload? ? render(:template => 'share_file/new_ajax_upload', :layout => false) : render_window_close
      return
    end

    @error_messages = []
    @owner_name = owner.name
    @categories_hash = ShareFile.get_tags_hash(@share_file.owner_symbol)
    ajax_upload? ? render(:template => 'share_file/new_ajax_upload', :layout => false) : render
  end

  # post action
  def create
    @error_messages = []
    unless params[:file]
      ajax_upload? ? render(:text => {:status => '400', :messages => [_("%{name} is mandatory.") % { :name => _('File') }]}.to_json) : render_window_close
      return
    end
    @share_file = ShareFile.new(params[:share_file])
    @share_file.user_id = current_user.id
    @share_file.publication_symbols_value = params[:publication_symbols_value]

    params[:file].each do |key, file|
      share_file = @share_file.clone
      if file.is_a?(ActionController::UploadedFile)
        share_file.file_name = file.original_filename
        share_file.content_type = file.content_type || Types::ContentType::DEFAULT_CONTENT_TYPE
      end
      share_file.file = file
      share_file.accessed_user = current_user

      if share_file.save
        # TODO #814のチケットを処理するタイミングで下記4行は無くす
        target_symbols = analyze_param_publication_type share_file
        target_symbols.each do |target_symbol|
          share_file.share_file_publications.create(:symbol => target_symbol)
        end
        share_file.upload_file file
      else
        error_message = share_file.file_name

        unless share_file.errors.empty?
          error_message << " ... #{share_file.errors.full_messages.join(",")}"
        end
        @error_messages << error_message
      end
    end

    if @error_messages.size == 0
      notice_message = n_('File was successfully uploaded.', 'Files were successfully uploaded.', params[:file].size)
      flash[:notice] = notice_message
      ajax_upload? ? render(:text => {:status => '200', :messages => [notice_message]}.to_json) : render_window_close
    else
      messages = []
      messages << _("Failed to upload file(s).")
      messages << n_("[Success:%{success} ", "[Successes:%{success} ", params[:file].size - @error_messages.size) % {:success => params[:file].size - @error_messages.size}
      messages << n_("Failure:%{failure}]", "Failures:%{failure}]", @error_messages.size) % {:failure => @error_messages.size}
      flash.now[:warn] = messages.join('')

      @reload_parent_window = (params[:file].size - @error_messages.size > 0)
      @share_file.errors.clear
      @owner_name = params[:owner_name]
      @categories_hash = ShareFile.get_tags_hash(@share_file.owner_symbol)
      ajax_upload? ? render(:text => {:status => '400', :messages => @error_messages}.to_json) : render(:action => "new")
    end
  end

  def edit
    begin
      @share_file = ShareFile.find(params[:id])
    rescue ActiveRecord::RecordNotFound => ex
      render_window_close
      return
    end

    unless @share_file.updatable?(current_user)
      render_window_close
      return
    end

    @error_messages = []
    @owner_name = params[:owner_name]
    @categories_hash = ShareFile.get_tags_hash(@share_file.owner_symbol)
  end

  # post action
  def update
    @share_file = ShareFile.find(params[:file_id])
    update_params = params[:share_file]
    update_params[:publication_symbols_value] = params[:publication_symbols_value]
    @share_file.accessed_user = current_user

    if @share_file.update_attributes(update_params)
      # TODO #814のチケットを処理するタイミングで下記5行は無くす
      @share_file.share_file_publications.clear
      target_symbols = analyze_param_publication_type @share_file
      target_symbols.each do |target_symbol|
        @share_file.share_file_publications.create(:symbol => target_symbol)
      end

      flash[:notice] = _('Updated.')
      render_window_close
    else
      @owner_name = params[:owner_name]
      @categories_hash = ShareFile.get_tags_hash(@share_file.owner_symbol)
      render :action => :edit
    end
  end

  # post action
  def destroy
    share_file = ShareFile.find(params[:id])

    unless share_file.updatable?(current_user)
      redirect_to_with_deny_auth
      return
    end

    share_file.destroy
    flash[:notice] = _("File was successfully deleted.")

    redirect_to :controller => share_file.owner_symbol_type, :action => share_file.owner_symbol_id, :id => 'share_file'
  end

  def list
    # TODO: インスタンス変数の数を減らす
    owner = current_target_user || current_target_group
    unless owner
      flash[:warn] = _("Specified share file owner does not exist.")
      redirect_to root_url
      return
    end

    @search = ShareFile.accessible(current_user).owned(owner)
    @search = @search.tagged(params[:category], "AND") if params[:category]
    @search =
      if params[:sort_type] == "file_name"
        @search.descend_by_file_name.search(params[:search])
      else
        @search.descend_by_date.search(params[:search])
      end
    @share_files = @search.paginate(:page => params[:page], :per_page => 10)

    respond_to do |format|
      format.html do
        if owner.is_a? User
          @main_menu = user_main_menu(owner)
          @title = user_title(owner)
          @tab_menu_option = user_menu_option(owner)
        elsif owner.is_a? Group
          @main_menu = _('Groups')
          @title = owner.name
          @tab_menu_option = { :gid => owner.gid }
        end
        @owner_name = owner.name
        params[:sort_type] ||= "date"
        flash.now[:notice] = _('No matching shared files found.') if @share_files.empty?
        render :layout => 'layout'
      end
      format.js {
        render :json => {
          :pages => {
            :first => 1,
            :previous => @share_files.previous_page,
            :next => @share_files.next_page,
            :last => @share_files.total_pages,
            :current => @share_files.current_page,
            :item_count => @share_files.total_entries },
          :share_files => @share_files.map{|s| share_file_to_json(s) }
        }
      }
    end
  end

  def download
    symbol_type_hash = { 'user'  => 'uid',
                         'group' => 'gid' }
    file_name =  params[:file_name]
    owner_symbol = "#{symbol_type_hash[params[:controller_name]]}:#{params[:symbol_id]}"

    unless share_file = ShareFile.find_by_file_name_and_owner_symbol(file_name, owner_symbol)
      raise ActiveRecord::RecordNotFound
    end

    unless share_file.readable?(current_user)
      redirect_to_with_deny_auth
      return
    end

    if downloadable?(params[:authenticity_token], share_file)
      unless File.exist?(share_file.full_path)
        flash[:warn] = _('Could not find the entity of the specified file. Contact system administrator.')
        return redirect_to(:controller => 'mypage', :action => "index")
      end

      share_file.create_history current_user.id
      # TODO inlineパラメタの有無でdisposition切り替えは微妙か? アクション分ける? 拡張子やContentTypeで自動判別する? 検討する。
      send_file(share_file.full_path, :filename => nkf_file_name(file_name), :type => share_file.content_type || Types::ContentType::DEFAULT_CONTENT_TYPE, :stream => false, :disposition => params[:inline] ? 'inline' : 'attachment')
    else
      @main_menu = @title = _('File Download')
      render :action => 'confirm_download', :layout => 'layout'
    end
  end

  def downloadable?(authenticity_token, share_file)
    return true if share_file.uncheck_authenticity?
    authenticity_token == form_authenticity_token ? true : false
  end

  def download_history_as_csv
    share_file = ShareFile.find(params[:id])

    unless share_file.updatable?(current_user)
      redirect_to_with_deny_auth
      return
    end

    csv_text, file_name = share_file.get_accesses_as_csv
    send_data(csv_text, :filename => nkf_file_name(file_name), :type => 'application/x-csv', :disposition => 'attachment')
  end

  # ajax action
  def clear_download_history
    unless share_file = ShareFile.find(:first, :conditions => ["id = ?", params[:id]])
      return false
    end

    unless share_file.updatable?(current_user)
      render :text => _('Operation unauthorized.'), :status => :forbidden
      return
    end

    share_file.share_file_accesses.clear
    render :text => _('Download history was successfully deleted.')
  end

private
  # TODO #814のチケットを処理するタイミングで下記メソッドは無くす
  def analyze_param_publication_type share_file
    target_symbols = []
    case  share_file.publication_type
    when "public"
      target_symbols << "sid:allusers"
    when "private"
      target_symbols << share_file.owner_symbol
      target_symbols << session[:user_symbol]
    when "protected"
      target_symbols = share_file.publication_symbols_value.split(/,/).map {|symbol| symbol.strip }
      target_symbols << session[:user_symbol]
    else
      raise _("Invalid parameter(s).")
    end
    target_symbols
  end

  def render_window_close
    need_reload = params[:reload] == 'false' ? false : true
    if need_reload
      render :text => "<script type='text/javascript'>window.opener.location.reload();window.close();</script>"
    else
      render :text => "<script type='text/javascript'>window.close();</script>"
    end
  end

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

end
