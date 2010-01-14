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

class Admin::Group < Group
  has_many :group_participations, :dependent => :destroy, :class_name => 'Admin::GroupParticipation'
  belongs_to :group_category, :class_name => 'Admin::GroupCategory'

  N_('Admin::Group|Name')
  N_('Admin::Group|Gid')
  N_('Admin::Group|Description')
  N_('Admin::Group|Protected')
  N_('Admin::Group|Group category')
  N_('Admin::Group|Deleted at')

  def self.search_columns
    %w(name gid description)
  end

  def topic_title
    name
  end

  def to_param
    id.to_s
  end
end
