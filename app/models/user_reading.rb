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

class UserReading < ActiveRecord::Base

  def self.create_or_update(user_id, board_entry_id, read = true)
    user_reading = UserReading.find_by_user_id_and_board_entry_id(user_id, board_entry_id)
    user_reading ||= UserReading.new(:user_id => user_id, :board_entry_id => board_entry_id)
    user_reading.read = read
    user_reading.checked_on = read ? Time.now : nil
    user_reading.notice_type = 'notice' if BoardEntry.find(board_entry_id).is_notice?
    user_reading.save
    user_reading
  end

end
