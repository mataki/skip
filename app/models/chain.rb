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

class Chain < ActiveRecord::Base
  belongs_to :from_user, :class_name => "User", :foreign_key => "from_user_id"
  belongs_to :to_user,   :class_name => "User", :foreign_key => "to_user_id"

  validates_presence_of :comment

  named_scope :order_new, proc { { :order => 'updated_on DESC' } }

  named_scope :limit, proc { |num| { :limit => num } }
end
