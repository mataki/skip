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

class Picture < ActiveRecord::Base
  belongs_to :user

  named_scope :active_user, proc {
    { :conditions => ['user_id IN (?)', User.active.map(&:id).uniq] }
  }

  named_scope :current, proc {
    { :conditions => ['active = ?', true] }
  }

  named_scope :order_user_name, proc {
    { :order => 'users.name ASC', :include => :user }
  }

  attr_accessor :file
  cattr_reader :max_file_size, :max_files_size_per_user
  @@max_file_size = 200.kilobyte
  @@max_files_size_per_user = 10

  N_('Picture|File')

  validates_format_of :content_type, :with => /^image/, :message =>_("Uploads are limited to pictures only.")

  def before_validation
    @filesize ||= 0
    if file
      self.name = base_part_of(file.original_filename)
      self.content_type = file.content_type
      self.data = file.read
      @filesize = file.size
    end
  end

  def validate
    errors.add_to_base(_("Picture could not be changed.")) unless Admin::Setting.enable_change_picture
    errors.add_to_base(_("File size too large.")) if @filesize > @@max_file_size
    errors.add_to_base(_("You can only upload %s pictures.") % @@max_files_size_per_user) if user && self.new_record? && user.pictures.size >= @@max_files_size_per_user
  end

  def base_part_of(file_name)
    name = File.basename(file_name)
    name.gsub(/[^\w._-]/, '')
  end

  def activate!
    ActiveRecord::Base.transaction do
      user.pictures.current.each do |picture|
        picture.update_attributes!(:active => false)
      end
      self.update_attributes!(:active => true)
    end
  end
end
