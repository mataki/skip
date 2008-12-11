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

class UserProfileValue < ActiveRecord::Base
  belongs_to :user
  belongs_to :user_profile_master

  validates_presence_of :user
  validates_presence_of :user_profile_master

  def validate
    if user_profile_master
      user_profile_master.input_type_processer.validate(user_profile_master, self)
    else
      errors.add_to_base(_("User profile master isn't assosiated"))
    end
  end
end
