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
  before_filter :check_params, :only => [:update, :revert]

  PNG_IMAGE_NAMES = %w(title_logo header_logo footer_logo).freeze
  BACKGROUND_IMAGE_NAMES = %w(background001 background002 background003 background004 background005 
                              background006 background007 background008 background009 background010).freeze
  N_('Admin::ImagesController|title_logo')
  N_('Admin::ImagesController|title_logo_description')
  N_('Admin::ImagesController|header_logo')
  N_('Admin::ImagesController|header_logo_description')
  N_('Admin::ImagesController|footer_logo')
  N_('Admin::ImagesController|footer_logo_description')
  N_('Admin::ImagesController|background')
  N_('Admin::ImagesController|background_description')
  N_('Admin::ImagesController|background001')
  N_('Admin::ImagesController|background002')
  N_('Admin::ImagesController|background003')
  N_('Admin::ImagesController|background004')
  N_('Admin::ImagesController|background005')
  N_('Admin::ImagesController|background006')
  N_('Admin::ImagesController|background007')
  N_('Admin::ImagesController|background008')
  N_('Admin::ImagesController|background009')
  N_('Admin::ImagesController|background010')

  def index
    @topics = [_(self.class.name.to_s)]
  end

  def update
    if request.get?
      return redirect_to(:action => :index)
    end
    @topics = [_(self.class.name.to_s)]
    image_file = params[params[:target].to_sym]
    unless valid_file?(image_file, :max_size => 300.kilobyte, :content_types => content_types)
      return render(:action => :index)
    end

    open("#{save_dir}/#{params[:target]}#{extentions}", 'wb') { |f| f.write(image_file.read) }
    flash[:notice] = _('%{target}を保存しました。' % {:target => _("Admin::ImagesController|#{params[:target]}")})
    redirect_to admin_images_path
  rescue Errno::EACCES => e
    flash.now[:error] = _('対象の画像を保存することが出来ませんでした。再度お試し頂くか管理者にお問い合わせ下さい。')
    render :action => :index, :target => params[:target], :status => :forbidden
  rescue => e
    flash.now[:error] = _('想定外のエラーが発生しました。管理者にお問い合わせ下さい。')
    e.backtrace.each { |message| logger.error message }
    render :action => :index, :target => params[:target], :status => :internal_server_error
  end

  def revert
    if request.get?
      return redirect_to(admin_images_path)
    end
    @topics = [_(self.class.name.to_s)]
    open("#{save_dir}/default_#{params[:target]}#{extentions}", 'rb') do |default_file|
      open("#{save_dir}/#{params[:target]}#{extentions}", 'wb') do |target_file|
        target_file.write(default_file.read)
      end
    end
    flash[:notice] = _('%{target}を保存しました。' % {:target => _("Admin::ImagesController|#{params[:target]}")})
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

  def check_params
    if params[:target].blank?
      redirect_to :action => :index
    end
    unless (PNG_IMAGE_NAMES + BACKGROUND_IMAGE_NAMES).include? params[:target]
      redirect_to "#{root_url}404.html"
    end
  end
end
