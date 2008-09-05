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

class Admin::User < User
  has_many :user_uids, :dependent => :destroy, :class_name => 'Admin::UserUid'
  has_many :openid_identifiers, :dependent => :destroy, :class_name => 'Admin::OpenidIdentifier'

  N_('Admin::User|Name')
  N_('Admin::User|Retired')
  N_('Admin::User|Admin')

  class << self
    alias :find :find_without_retired_skip
  end

  def self.search_colomns
    "name like :lqs"
  end

  def topic_title
    name
  end
end
