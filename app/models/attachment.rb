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

class Attachment < ActiveRecord::Base
  include ::QuotaValidation
  include ::SkipEmbedded::ValidationsFile

  QUOTA_EACH = QuotaValidation.lookup_setting(self,:each)

  has_attachment :storage => :db_file,
                 :size => 1..QuotaValidation.lookup_setting(self, :each),
                 :processor => :none

  attr_accessible :uploaded_data, :user_id, :db_file_id

  attachment_options.delete(:size) # エラーメッセージカスタマイズのため、自分でバリデーションをかける

  validates_inclusion_of :size, :in => 1..QUOTA_EACH, :message =>
    "#{QUOTA_EACH.to_i/1.megabyte}Mバイト以上のファイルはアップロードできません。"
  validates_quota_of :size, :system, :message =>
    "のシステム全体における保存領域の利用容量が最大値を越えてしまうためアップロードできません。"

  belongs_to :user
  belongs_to :page

  validates_presence_of :display_name
  validates_as_attachment

  def filename=(new_name)
    super
    self.display_name = new_name
  end

  private
  def validate_on_create
    adapter = ValidationsFileAdapter.new(self)

    valid_extension_of_file(adapter)
    valid_content_type_of_file(adapter)
  end

end
