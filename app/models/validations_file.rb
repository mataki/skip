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

module ValidationsFile
  include Types::ContentType
  def valid_presence_of_file(file)
    unless file.is_a?(ActionController::UploadedFile)
      errors.add_to_base "ファイルが指定されていません。"
      return false
    end
    true
  end

  def valid_extension_of_file(file)
    unless verify_extension? file.original_filename, file.content_type
      errors.add_to_base "この形式のファイルは、アップロードできません。"
    end
  end

  def valid_content_type_of_file(file)
    extension = file.original_filename.split('.').last
    if(content_types = CONTENT_TYPE_IMAGES[extension.to_sym])
      unless content_types.split(',').include?(file.content_type)
        errors.add_to_base "この形式のファイルは、アップロードできません。"
        return false;
      end
    end
    true
  end

  def valid_size_of_file(file)
    if file.size == 0
      errors.add_to_base "存在しないもしくはサイズ０のファイルはアップロードできません。"
    elsif file.size > INITIAL_SETTINGS['max_share_file_size'].to_i
      errors.add_to_base "#{INITIAL_SETTINGS['max_share_file_size'].to_i/1.megabyte}Mバイト以上のファイルはアップロードできません。"
    end
  end

  def valid_max_size_per_owner_of_file(file, owner_symbol)
    if (FileSizeCounter.per_owner(owner_symbol) + file.size) > INITIAL_SETTINGS['max_share_file_size_per_owner'].to_i
      errors.add_to_base "共有ファイル保存領域の利用容量が最大値を越えてしまうためアップロードできません。"
    end
  end

  def valid_max_size_of_system_of_file(file)
    if (FileSizeCounter.per_system + file.size) > INITIAL_SETTINGS['max_share_file_size_of_system'].to_i
      errors.add_to_base "システム全体における共有ファイル保存領域の利用容量が最大値を越えてしまうためアップロードできません。"
    end
  end

  class FileSizeCounter
    def self.per_owner owner_symbol
      sum = 0
      sum += ShareFile.total_share_file_size(owner_symbol)
      sum
    end
    def self.per_system
      sum = 0
      Dir.glob("#{ENV['SHARE_FILE_PATH']}/**/*").each do |f|
        sum += File.stat(f).size
      end
      sum
    end
  end

  private
  def verify_extension? file_name, content_type
    !disallow_extensions.any?{|extension| extension == file_name.split('.').last } &&
      !disallow_content_types.any?{|content| content == content_type }
  end

  def disallow_content_types
    ['text/html', 'application/x-javascript', 'image/bmp']
  end

  def disallow_extensions
    ['html', 'htm', 'js', 'bmp']
  end
end
