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

  validates_presence_of :board_entry_id
  validates_presence_of :contents
  validates_presence_of :user_id

  def comment_created_time
    format = _("%B %d %Y %H:%M")
    created_on.strftime(format)
  end
end
