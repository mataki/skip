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

class Admin::DocumentsController < Admin::ApplicationController
  before_filter :check_params

  CONTENT_NAMES = %w(about_this_site rules)
  N_('Admin::DocumentsController|about_this_site')
  N_('Admin::DocumentsController|about_this_site_description')
  N_('Admin::DocumentsController|rules')
  N_('Admin::DocumentsController|rules_description')

  def index
    @content_name = _(self.class.name + '|' + params[:target])
    @document = ''
    @document = open(RAILS_ROOT + "/public/custom/#{params[:target]}.html", 'r') { |f| s = f.read }
    @topics = topics
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
    begin_update do
      document = params[:documents]["#{params[:target]}"]
      open(RAILS_ROOT + "/public/custom/#{params[:target]}.html", 'w') { |f| f.write(document) }
    end
  end

  def revert
    begin_update do
      @topics = [_(self.class.name.to_s)]
      save_dir = "#{RAILS_ROOT}/public/custom"
      extentions = '.html'
      open("#{save_dir}/default_#{params[:target]}#{extentions}", 'r') do |default_file|
        open("#{save_dir}/#{params[:target]}#{extentions}", 'w') do |target_file|
          target_file.write(default_file.read)
        end
      end
    end
  end

  private
  def check_params
    if params[:target].blank?
      if action_name == 'index'
        @topics = topics
        render :action => :index
      end
    else
      unless CONTENT_NAMES.include? params[:target]
        redirect_to "#{root_url}404.html"
      end
    end
  end

  def begin_update(&block)
    if request.get?
      return redirect_to(admin_documents_path)
    end
    yield
    flash[:notice] = _('%{target}を保存しました。' % {:target => _("Admin::DocumentsController|#{params[:target]}")})
    redirect_to admin_documents_path(:target => params[:target])
  rescue Errno::EACCES => e
    flash.now[:error] = _('対象のコンテンツを保存することが出来ませんでした。再度お試し頂くか管理者にお問い合わせ下さい。')
    render :action => :index, :target => params[:target], :status => :forbidden
  rescue => e
    flash.now[:error] = _('想定外のエラーが発生しました。管理者にお問い合わせ下さい。')
    e.backtrace.each { |message| logger.error message }
    render :action => :index, :target => params[:target], :status => :internal_server_error
  end

  def topics
    [[_('Admin::DocumentsController'), admin_documents_path]]
  end
end
