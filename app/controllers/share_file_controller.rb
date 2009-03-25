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

class ShareFileController < ApplicationController
  include IframeUploader
  layout 'subwindow'

  verify :method => :post, :only => [ :create, :update, :destroy, :download_history_as_csv, :clear_download_history ],
         :redirect_to => { :action => :index }

  def new
    @share_file = ShareFile.new(:user_id => current_user.id, :owner_symbol => params[:owner_symbol])

    unless @share_file.updatable?(current_user)
      ajax_upload? ? render(:template => 'share_file/new_ajax_upload', :layout => false) : render_window_close
      return
    end

    params[:publication_type] = "public" if Symbol.split_symbol(@share_file.owner_symbol).first=="uid"
    params[:publication_type] ||= "private"
    params[:publication_symbols_value] = ""

    @error_messages = []
    @owner_name = params[:owner_name]
    @categories_hash = ShareFile.get_tags_hash(@share_file.owner_symbol)
    ajax_upload? ? render(:template => 'share_file/new_ajax_upload', :layout => false) : render
  end

  # post action
  def create
    @error_messages = []
    unless params[:file]
      ajax_upload? ? render(:template => 'share_file/new_ajax_upload', :layout => false) : render_window_close
      return
    end
    @share_file = ShareFile.new(params[:share_file])
    @share_file.user_id = current_user.id
    @share_file.publication_type = params[:publication_type]
    @share_file.publication_symbols_value = params[:publication_type]=='protected' ? params[:publication_symbols_value] : ""

    params[:file].each do |key, file|
      share_file = @share_file.clone
      if file.is_a?(ActionController::UploadedFile)
        share_file.file_name = file.original_filename
        share_file.content_type = file.content_type || Types::ContentType::DEFAULT_CONTENT_TYPE
      end
      share_file.file = file
      share_file.accessed_user = current_user

      if share_file.save
        target_symbols = analyze_param_publication_type
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
      flash[:notice] = _('ファイルのアップロードに成功しました。')
      ajax_upload? ? render(:template => 'share_file/new_ajax_upload', :layout => false) : render_window_close
    else
      flash.now[:warning] = "ファイルのアップロードに失敗しました。<br/>"
      flash.now[:warning] << "[成功:#{params[:file].size - @error_messages.size} 失敗:#{@error_messages.size}]"

      @reload_parent_window = (params[:file].size - @error_messages.size > 0)
      @share_file.errors.clear
      @owner_name = params[:owner_name]
      @categories_hash = ShareFile.get_tags_hash(@share_file.owner_symbol)
      ajax_upload? ? render(:template => 'share_file/new_ajax_upload', :layout => false) : render(:action => "new")
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

    params[:publication_symbols_value] = ""
    if @share_file.public?
      params[:publication_type] = "public"
    elsif @share_file.private?
      params[:publication_type] = "private"
    else
      params[:publication_type] = "protected"
      params[:publication_symbols_value] = @share_file.publication_symbols_value
    end

    @error_messages = []
    @owner_name = params[:owner_name]
    @categories_hash = ShareFile.get_tags_hash(@share_file.owner_symbol)
  end

  # post action
  def update
    @share_file = ShareFile.find(params[:file_id])
    update_params = params[:share_file]
    update_params[:publication_type] = params[:publication_type]
    update_params[:publication_symbols_value] = params[:publication_type]=='protected' ? params[:publication_symbols_value] : ""
    @share_file.accessed_user = current_user

    if @share_file.update_attributes(update_params)
      @share_file.share_file_publications.clear
      target_symbols = analyze_param_publication_type
      target_symbols.each do |target_symbol|
        @share_file.share_file_publications.create(:symbol => target_symbol)
      end

      flash[:notice] = _('更新しました。')
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
    flash[:notice] = _("ファイルの削除に成功しました。")

    redirect_to :controller => share_file.owner_symbol_type, :action => share_file.owner_symbol_id, :id => 'share_file'
  end

  def list
    redirect_to_with_deny_auth and return if not parent_controller

    @main_menu = parent_controller.send!(:main_menu)
    @title = parent_controller.send!(:title)
    @tab_menu_source = parent_controller.send!(:tab_menu_source)
    @tab_menu_option = parent_controller.send!(:tab_menu_option)

    @owner_name = params[:owner_name]
    @owner_symbol = params[:id]
    @categories = ShareFile.get_tags @owner_symbol
    params[:controller] = parent_controller.params[:controller]
    params[:action] = parent_controller.params[:action]

    params[:sort_type] ||= "date"
    params_hash = { :owner_symbol => @owner_symbol, :category => params[:category],
                    :keyword => params[:keyword], :without_public => params[:without_public] }
    find_params = ShareFile.make_conditions(login_user_symbols, params_hash)
    order_by = (params[:sort_type] == "date" ? "date desc" : "file_name")

    @pages, @share_files = paginate(:share_files,
                                    :conditions => find_params[:conditions],
                                    :include => find_params[:include],
                                    :order => order_by,
                                    :per_page => 10)
    unless @share_files && @share_files.size > 0
      flash.now[:notice] = '該当するファイルはありませんでした。'
    end

    # 編集メニューの表示有無
    @visitor_is_uploader = params[:visitor_is_uploader]
    respond_to do |format|
      format.html { render :layout => 'layout' }
      format.js {
        render :json => {
          :pages => {
            :first => 1,
            :previous => @pages.current.previous.to_i,
            :next => @pages.current.next.to_i,
            :last => @pages.last.to_i,
            :current => @pages.current.number,
            :item_count => @pages.item_count },
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
        flash[:warning] = '指定されたファイルの実体が存在しません。お手数ですが管理者にご連絡をお願いいたします。'
        return redirect_to(:controller => 'mypage', :action => "index")
      end

      share_file.create_history current_user.id
      send_file(share_file.full_path, :filename => nkf_file_name(file_name), :type => share_file.content_type || Types::ContentType::DEFAULT_CONTENT_TYPE, :stream => false, :disposition => 'attachment')
    else
      @main_menu = @title = 'ファイルのダウンロード'
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
      render :text => _('この操作は、許可されていません。'), :status => :forbidden
      return
    end

    share_file.share_file_accesses.clear
    render :text => _('ダウンロード履歴の削除に成功しました。')
  end

private
  def analyze_param_publication_type
    target_symbols = []
    case params[:publication_type]
    when "public"
      target_symbols << "sid:allusers"
    when "private"
      target_symbols << params[:share_file][:owner_symbol]
      target_symbols << session[:user_symbol]
    when "protected"
      target_symbols = params[:publication_symbols_value].split(/,/).map {|symbol| symbol.strip }
      target_symbols << session[:user_symbol]
    else
      raise "パラメータが不正です"
    end
    target_symbols
  end

  def render_window_close
    render :text => "<script type='text/javascript'>window.opener.location.reload();window.close();</script>"
  end

  def nkf_file_name(file_name)
    agent = request.cgi.env_table["HTTP_USER_AGENT"]
    return  NKF::nkf('-Ws', file_name) if agent.include?("MSIE") and not agent.include?("Opera")
    return file_name
  end

  def share_file_to_json(share_file)
    returning(share_file.attributes) do |json|
      json[:src] = share_file_url(
        :controller_name => share_file.owner_symbol_type,
        :symbol_id => share_file.owner_symbol_id,
        :file_name => share_file.file_name)
      json[:file_type] = share_file.image_extention? ? 'image' : ''
    end
  end
end
