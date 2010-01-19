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

class Admin::BoardEntry < BoardEntry
  has_many :board_entry_comments, :dependent => :destroy, :class_name => 'Admin::BoardEntryComment'
  N_('Admin::BoardEntry|Title')
  N_('Admin::BoardEntry|Contents')
  N_('Admin::BoardEntry|Category')
  N_('Admin::BoardEntry|Entry type')
  N_('Admin::BoardEntry|User')
  N_('Admin::BoardEntry|Symbol')
  N_('Admin::BoardEntry|Publication type')

  def self.search_columns
    %w(title contents category)
  end

  def topic_title
    title[/.{1,10}/] + "..."
  end
end
