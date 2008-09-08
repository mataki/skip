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

class Admin::DocumentsController < Admin::ApplicationController
  before_filter :check_params

  CONTENT_NAMES = %w(about_this_site confirm_desc introduction login_desc rules)
  N_('Admin::DocumentsController|about_this_site')
  N_('Admin::DocumentsController|about_this_site_description')
  N_('Admin::DocumentsController|confirm_desc')
  N_('Admin::DocumentsController|confirm_desc_description')
  N_('Admin::DocumentsController|introduction')
  N_('Admin::DocumentsController|introduction_description')
  N_('Admin::DocumentsController|login_desc')
  N_('Admin::DocumentsController|login_desc_description')
  N_('Admin::DocumentsController|rules')
  N_('Admin::DocumentsController|rules_description')

  def index
    @content_name = _(self.class.name + '|' + params[:target])
    @document = ''
    @document = open(RAILS_ROOT + "/public/custom/#{params[:target]}.html", 'r') { |f| s = f.read }
    @topics = [[_('静的コンテンツ管理'), admin_documents_path]]
    @topics << @content_name
  rescue Errno::EACCES => e
    flash.now[:error] = _('対象のコンテンツを開くことが出来ませんでした。')
    render :status => :forbidden
  rescue Errno::ENOENT => e
    flash.now[:error] = _('対象のコンテンツが存在しません。')
    render :status => :not_found
  rescue => e
    flash.now[:error] = _('想定外のエラーが発生しました。管理者にお問い合わせ下さい。')
    logger.error e
    e.backtrace.each { |message| logger.error message }
    render :status => :internal_server_error
  end

  def update
    document = params[:documents]["#{params[:target]}"]
    open(RAILS_ROOT + "/public/custom/#{params[:target]}.html", 'w') { |f| f.write(document) }
    flash[:notice] = _('保存しました。')
    redirect_to admin_documents_path(:target => params[:target])
  rescue Errno::EACCES => e
    flash.now[:error] = _('対象のコンテンツを保存することが出来ませんでした。再度お試し頂くか管理者にお問い合わせ下さい。')
    render :action => :index, :target => params[:target], :status => :forbidden
  rescue => e
    flash.now[:error] = _('想定外のエラーが発生しました。管理者にお問い合わせ下さい。')
    e.backtrace.each { |message| logger.error message }
    render :action => :index, :target => params[:target], :status => :internal_server_error
  end

  private
  def check_params
    if params[:target].blank?
      if action_name == 'index'
        @topics = [[_('静的コンテンツ管理'), admin_documents_path]]
        render :action => :index
      end
    else
      unless CONTENT_NAMES.include? params[:target]
        redirect_to "#{root_url}404.html"
      end
    end
  end
end
