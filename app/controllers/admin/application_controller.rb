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

class Admin::ApplicationController < ApplicationController
  layout 'admin/application'
  before_filter :require_admin, :setup_layout

  def require_admin
    unless current_user.admin
      redirect_to root_url
      return false
    end
  end

  def setup_layout
<<<<<<< HEAD:app/controllers/admin/application_controller.rb
    @title = @main_menu = "設定・管理"
=======
    @title = @main_menu = _("System Administration")
>>>>>>> for_i18n:app/controllers/admin/application_controller.rb
  end

  protected
  def valid_file?(uploaded_file, options = {})
    options = {:max_size => 1.megabyte, :content_types => []}.merge(options)
    if uploaded_file.blank?
      flash.now[:error] = _('File not specified.')
      return false
    end

    if uploaded_file.size == 0
      flash.now[:error] = _('0 file size detected.')
      return false
    end

    if uploaded_file.size > options[:max_size]
      flash.now[:error] = _('File size exceeded the limit.')
      return false
    end

    if options[:extension] && !options[:extension].empty?
      unless options[:extension] == uploaded_file.original_filename.split('.').last.downcase
        flash.now[:error] = _('指定された拡張子のファイルはアップロード出来ません。')
        return false
      end
    end

    if options[:content_types] && !options[:content_types].empty?
      unless options[:content_types].include?(uploaded_file.content_type)
        flash.now[:error] = _('Disallowed file type.')
        return false
      end
    end
    true
  end
end
