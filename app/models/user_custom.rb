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

class UserCustom < ActiveRecord::Base
  # TODO マイページのカレンダー表示機能を完全に無くすことが決まったらdisplay_calendarカラムを無くすmigrationを書く
  validates_presence_of :theme
  validates_presence_of :display_entries_format
  validates_inclusion_of :display_entries_format, :in => %w(tabs flat)
  validates_presence_of :editor_mode
  validates_inclusion_of :editor_mode, :in => %w(richtext hiki)

  def to_s
    "user_id:" + user_id.to_s + ", theme:" + theme
  end
end
