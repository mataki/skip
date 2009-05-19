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

class UserProfileMasterCategory < ActiveRecord::Base
  has_many :user_profile_masters

  validates_presence_of :name
  validates_presence_of :sort_order

  class << self
    def find_with_order_by_sort_order(*args)
      with_scope(:find => { :order => "sort_order" } ) do
        find_without_order_by_sort_order(*args)
      end
    end
    alias_method_chain :find, :order_by_sort_order
  end

  def deletable?
    unless self.user_profile_masters.empty?
      errors.add_to_base(_('対象のプロフィールカテゴリに属するプロフィール項目が登録されているため削除出来ません。このカテゴリに登録されているプロフィール項目を全て削除した後実行してください。'))
      return false
    end
    true
  end
end
