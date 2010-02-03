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

class Notice < ActiveRecord::Base
  belongs_to :target, :polymorphic => true

  validates_uniqueness_of :user_id, :scope => [:target_id, :target_type]

  named_scope :subscribed, proc { |owner|
    { :conditions => ['target_id = ? AND target_type = ?', owner.id, owner.class.name] }
  }

  def self.trace_comments_count user
    comment_count = BoardEntry.accessible(user).commented(user).unread(user).count
  end

  def self.track_of_bookmarks_count user
    bookmark_count = 0
    if (bookmarks = Bookmark.find(:all,
                                  :conditions => ["bookmark_comments.user_id = ? and url like '/page/%'", user.id],
                                  :include => [:bookmark_comments])).size > 0
      urls = UserReading.find(:all,
                              :select => "board_entry_id",
                              :conditions => ["user_readings.read = ? and user_id = ?", false, user.id])
      urls.map! {|item| '/page/'+item.board_entry_id.to_s }

      bookmarks.each { |bookmark| bookmark_count+=1 if urls.include?(bookmark.url) } if urls.size > 0
    end
    bookmark_count
  end

  def unread_count user
    @unread_count ||= BoardEntry.accessible(user).owned(target).unread(user).count
  end
end
