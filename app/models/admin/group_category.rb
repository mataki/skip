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

class Admin::GroupCategory < GroupCategory
  has_many :groups, :class_name => 'Admin::Group'

  N_('Admin::GroupCategory|Code')
  N_('Admin::GroupCategory|Code description')
  N_('Admin::GroupCategory|Name')
  N_('Admin::GroupCategory|Name description')
  N_('Admin::GroupCategory|Icon')
  N_('Admin::GroupCategory|Icon description')
  N_('Admin::GroupCategory|Description')
  N_('Admin::GroupCategory|Description description')
  N_('Admin::GroupCategory|Sort order')
  N_('Admin::GroupCategory|Sort order description')
  N_('Admin::GroupCategory|Initial selected')
  N_('Admin::GroupCategory|Initial selected description')

  def topic_title
    name
  end
end
