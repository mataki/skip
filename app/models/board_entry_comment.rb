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

class BoardEntryComment < ActiveRecord::Base
  acts_as_tree :order => :created_on
  belongs_to :user
  belongs_to :board_entry, :counter_cache => true

  validates_presence_of :board_entry_id
  validates_presence_of :contents
  validates_presence_of :user_id

  named_scope :active_user, proc {
    { :conditions => ['user_id IN (?)', User.active.map(&:id).uniq] }
  }

  named_scope :roots, proc {
    { :conditions => ['board_entry_comments.parent_id is NULL'] }
  }

  named_scope :order_new, proc { { :order => 'board_entry_comments.updated_on DESC' } }

  named_scope :order_old, proc {
    { :order => 'updated_on' }
  }

  cattr_reader :limit_level
  @@limit_level = 4

  def after_save
    board_entry.reload.update_attribute :updated_on, Time.now
  end

  def comment_created_time
    format = _("%B %d %Y %H:%M")
    created_on.strftime(format)
  end

  def editable? user
    return false unless user
    # TODO 権限のあるBoardEntryを取得するnamed_scopeに置き換える
    find_params = BoardEntry.make_conditions(user.belong_symbols, {:id => self.board_entry_id})
    board_entry = BoardEntry.find(:first,
                                  :conditions => find_params[:conditions],
                                  :include => find_params[:include])
    !!(board_entry && self.user_id == user.id)
  end

  # TODO viewのネストレベル絡みのロジックはこれを使いたい
  def level
    @level ||= ancestors.size + 1
  end
end
