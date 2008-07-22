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

class Picture < ActiveRecord::Base
  belongs_to :user, :class_name => "User", :foreign_key => "user_id"

  validates_format_of :content_type, :with => /^image/, :message =>"アップロードできるのは画像のみです"

  def picture=(picture_field)
    self.name = base_part_of(picture_field.original_filename)
    self.content_type = picture_field.content_type.chomp
    self.data = picture_field.read
    @filesize = picture_field.size
  end

  def base_part_of(file_name)
    name = File.basename(file_name)
    name.gsub(/[^\w._-]/, '')
  end

  def validate
    @picture = Picture.find(:first, :conditions =>['user_id = ?', self.user_id])
    errors.add("", "画像は１つまでしかアップロードできません。") if @picture
    errors.add("", "ファイルサイズが大きすぎます。") if @filesize > 65535
  end
end
