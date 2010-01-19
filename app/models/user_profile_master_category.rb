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

class UserProfileMasterCategory < ActiveRecord::Base
  has_many :user_profile_masters

  validates_presence_of :name
  validates_presence_of :sort_order

  default_scope :order => "sort_order"

  def deletable?
    unless self.user_profile_masters.empty?
      errors.add_to_base(_('Profile category could not be deleted due to profile items belonging to itself. Delete all profile items belonging to this profile category before you delete it.'))
      return false
    end
    true
  end
end
