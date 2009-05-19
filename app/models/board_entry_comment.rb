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

class BoardEntryComment < ActiveRecord::Base
  acts_as_tree :order => :created_on
  belongs_to :user
  belongs_to :board_entry, :counter_cache => true

  validates_presence_of :board_entry_id, :message =>'は必須です'
  validates_presence_of :contents, :message =>'は必須です'
  validates_presence_of :user_id, :message =>'は必須です'

  class << self
    HUMANIZED_ATTRIBUTE_KEY_NAMES = {
      "board_entry_id" => "コメント先の投稿",
      "contents" => "内容",
      "user_id" => "著者"
    }
    def human_attribute_name(attribute_key_name)
      HUMANIZED_ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
    end
  end

  def comment_created_time
    format = "%Y年%m月%d日 %H:%M"
    created_on.strftime(format)
  end

end
