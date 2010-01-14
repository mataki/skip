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

class Attachment < ActiveRecord::Base
  include ::QuotaValidation
  include ::SkipEmbedded::ValidationsFile

  QUOTA_EACH =  SkipEmbedded::InitialSettings['max_share_file_size'].to_i || 10.megabytes

  has_attachment :storage => :file_system,
                 :size => 1..QUOTA_EACH,
                 :processor => :none

  attr_accessible :uploaded_data, :user_id

  attachment_options.delete(:size) # エラーメッセージカスタマイズのため、自分でバリデーションをかける

  validates_inclusion_of :size, :in => 1..QUOTA_EACH, :message =>
    "#{QUOTA_EACH/1.megabyte}Mバイト以上のファイルはアップロードできません。"

  belongs_to :user
  belongs_to :page

  validates_presence_of :display_name
  validates_as_attachment

  def filename=(new_name)
    super
    self.display_name = new_name
  end

  # Override
  def full_filename(thumbnail=nil)
    File.join(RAILS_ROOT, SkipEmbedded::InitialSettings['share_file_path'], Attachment.table_name, *partitioned_path(thumbnail_name_for(thumbnail)))
  end

  # Override
  def base_path
    @base_path = File.join(RAILS_ROOT, SkipEmbedded::InitialSettings['share_file_path'])
  end

  private
  def validate_on_create
    adapter = ValidationsFileAdapter.new(self)

    valid_extension_of_file(adapter)
    valid_content_type_of_file(adapter)
    valid_max_size_of_system_of_file self.size
  end

end
