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

class ChainTag < ActiveRecord::Base
  belongs_to :chain
  belongs_to :tag

  def self.tags_used_to target_user, except_user = nil
    scope = Tag.against_chains_by(target_user)
    scope = scope.except_follow_chains_by(except_user) if except_user
    scope.order_new
  end

  def self.popular_tags_used_by_only user, limit = 20
    Tag.follow_chains_by(user).order_new.limit(limit)
  end

  def self.popular_tags_used_by_except user, limit = 10
    Tag.on_chains.order_popular.except_follow_chains_by(user).limit(limit)
  end

  def self.popular_tag_names limit = 40
    Tag.on_chains.order_popular.limit(limit).map(&:name)
  end
end
