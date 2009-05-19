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

class EntryTrackback < ActiveRecord::Base
  belongs_to :board_entry, :counter_cache => true
  belongs_to :tb_entry, :foreign_key => 'tb_entry_id', :class_name => 'BoardEntry'

  validates_presence_of :board_entry_id, :message =>'は必須です'
  validates_presence_of :tb_entry_id, :message =>'は必須です'

  class << self
    HUMANIZED_ATTRIBUTE_KEY_NAMES = {
      "board_entry_id" => "話題を元に書いた記事",
      "tb_entry_id" => "話題の元になった記事"
    }
    def human_attribute_name(attribute_key_name)
      HUMANIZED_ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
    end
  end
end
