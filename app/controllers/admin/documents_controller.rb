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
    flash.now[:error] = _('Failed to open the content.')
    render :status => :forbidden
  rescue Errno::ENOENT => e
    flash.now[:error] = _('Content not found.')
    render :status => :not_found
  rescue => e
    flash.now[:error] = _('Unexpected error occured. Contact administrator.')
    logger.error e
    e.backtrace.each { |message| logger.error message }
    render :status => :internal_server_error
  end

  HTML_WRAPPER = <<EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html lang="ja" xml:lang="ja" xmlns="http://www.w3.org/1999/xhtml">
<head xmlns="">
  <meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
  <title>TITLE_STR</title>
</head>
<body style="padding: 10px;">
BODY
</body>
</html>
EOF

  def update
    begin_update do
      document = params[:documents]["#{params[:target]}"]
      document = HTML_WRAPPER.sub('BODY', document)
      document = document.sub('TITLE_STR', ERB::Util.h(params[:target]).humanize)
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
    flash[:notice] = _('%{target} was successfully saved.') % {:target => s_("Admin::DocumentsController|#{params[:target]}")}
    redirect_to admin_documents_path(:target => params[:target])
  rescue Errno::EACCES => e
    flash.now[:error] = _('Failed to save the content.  Try again or contact administrator.')
    render :action => :index, :target => params[:target], :status => :forbidden
  rescue => e
    flash.now[:error] = _('Unexpected error occured. Contact administrator.')
    e.backtrace.each { |message| logger.error message }
    render :action => :index, :target => params[:target], :status => :internal_server_error
  end

  def topics
    [[_('Admin::DocumentsController'), admin_documents_path]]
  end
end
