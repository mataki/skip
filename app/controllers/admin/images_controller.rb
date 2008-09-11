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

class Admin::ImagesController < Admin::ApplicationController

  PNG_IMAGE_NAMES = %w(title_logo header_logo footer_logo)
  BACKGROUND_IMAGE_NAMES = %w(background001 background002 background003 background004 background005 
                              background006 background007 background008 background009 background010)
  N_('Admin::ImagesController|title_logo')
  N_('Admin::ImageController|title_logo_description')
  N_('Admin::ImagesController|header_logo')
  N_('Admin::ImageController|header_logo_description')
  N_('Admin::ImagesController|footer_logo')
  N_('Admin::ImageController|footer_logo_description')
  N_('Admin::ImagesController|background')
  N_('Admin::ImageController|background_description')

  def index
    @topics = [_(self.class.name.to_s)]
  end

  def update
    @topics = [_(self.class.name.to_s)]
    image_file = params[params[:target].to_sym]
    unless valid_file?(image_file, :max_size => 300.kilobyte, :content_types => content_types)
      return render(:action => :index)
    end

    open("#{save_dir}/#{params[:target]}#{extentions}", 'wb') { |f| f.write(image_file.read) }
    flash[:notice] = _('保存しました。')
    redirect_to admin_images_path
  rescue Errno::EACCES => e
    flash.now[:error] = _('対象の画像を保存することが出来ませんでした。再度お試し頂くか管理者にお問い合わせ下さい。')
    render :action => :index, :target => params[:target], :status => :forbidden
  rescue => e
    flash.now[:error] = _('想定外のエラーが発生しました。管理者にお問い合わせ下さい。')
    e.backtrace.each { |message| logger.error message }
    render :action => :index, :target => params[:target], :status => :internal_server_error
  end

  private
  def extentions
    BACKGROUND_IMAGE_NAMES.include?(params[:target]) ? '.jpg' : '.png'
  end

  def content_types
    BACKGROUND_IMAGE_NAMES.include?(params[:target]) ? ['image/jpg', 'image/jpeg'] : ['image/png']
  end

  def save_dir
    base_dir = "#{RAILS_ROOT}/public/custom/images"
    BACKGROUND_IMAGE_NAMES.include?(params[:target]) ? "#{base_dir}/titles" : base_dir
  end
end
