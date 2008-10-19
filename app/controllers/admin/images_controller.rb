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
  N_('Admin::ImagesController|favicon')
  N_('Admin::ImagesController|favicon_description')

  def index
    @topics = [_(self.class.name.to_s)]
  end

  def update
    image = new_image
    begin_update do
      @topics = [_(self.class.name.to_s)]
      unless valid_file?(image.file, :max_size => image.class.max_size, :content_types => image.content_types)
        return render(:action => :index)
      end
      open(image.full_path, 'wb') { |f| f.write(image.file.read) }
    end
  end

  def revert
    image = new_image
    begin_update do
      @topics = [_(self.class.name.to_s)]
      open(image.default_full_path, 'rb') do |default_file|
        open(image.full_path, 'wb') do |target_file|
          target_file.write(default_file.read)
        end
      end
    end
  end

  class BaseImage
    attr_reader :file, :file_name, :content_types, :base_dir, :save_dir
    def initialize param = {}
      @file_name = param[:target]
      @file = param[self.file_name.to_sym]
      @content_types = []
      @base_dir = @save_dir = "#{RAILS_ROOT}/public"
    end

    def full_path
      "#{@save_dir}/#{@file_name}.#{self.class.extentions}"
    end

    def default_full_path
      "#{@save_dir}/default_#{@file_name}.#{self.class.extentions}"
    end

    def self.extentions
      'png'
    end

    def self.max_size
      300.kilobyte
    end
  end

  class LogoImage < BaseImage
    IMAGE_NAMES = %w(title_logo header_logo).freeze
    def initialize param = {}
      super
      @content_types = ['image/png']
      @save_dir = "#{base_dir}/custom/images"
    end

    def self.extentions
      'png'
    end
  end

  class BackGroundImage < BaseImage
    IMAGE_NAMES = %w(background001 background002 background003 background004 background005
                     background006 background007 background008 background009 background010).freeze
    def initialize param = {}
      super
      @content_types = ['image/jpg', 'image/jpeg']
      @save_dir = "#{base_dir}/custom/images/titles"
    end

    def self.extentions
      'jpg'
    end
  end

  class FaviconImage < BaseImage
    IMAGE_NAMES = ['favicon'].freeze
    def initialize param = {}
      super
    end

    def self.extentions
      'ico'
    end

    def self.max_size
      10.kilobyte
    end
  end
  private
  def check_params
    if params[:target].blank?
      redirect_to :action => :index
    end
    unless (LogoImage::IMAGE_NAMES + BackGroundImage::IMAGE_NAMES + FaviconImage::IMAGE_NAMES).include? params[:target]
      redirect_to "#{root_url}404.html"
    end
  end

  def begin_update(&block)
    if request.get?
      return redirect_to(admin_images_path)
    end
    yield
    ActionView::Base.computed_public_paths.clear
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

  def new_image
    if LogoImage::IMAGE_NAMES.include?(params[:target])
      LogoImage.new params
    elsif BackGroundImage::IMAGE_NAMES.include?(params[:target])
      BackGroundImage.new params
    else
      FaviconImage.new params
    end
  end
end
