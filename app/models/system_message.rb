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

class SystemMessage < ActiveRecord::Base
  belongs_to :user
  serialize :message_hash

  MESSAGE_TYPES = %w(COMMENT TRACKBACK CHAIN QUESTION JOIN LEAVE APPROVAL_OF_JOIN DISAPPROVAL_OF_JOIN FORCED_JOIN FORCED_LEAVE)

  named_scope :unsents, proc {
    {
      :conditions => ['send_flag = ?', false],
      :joins => 'LEFT JOIN user_message_unsubscribes USING(user_id, message_type)',
      :readonly => false
    }
  }

  named_scope :limit, proc { |num| { :limit => num } }

  def self.create_message attributes
    create(attributes) unless SystemMessage.user_id_eq(attributes[:user_id]).message_type_eq(attributes[:message_type]).map(&:message_hash).any? { |message_hash| message_hash == attributes[:message_hash] }
  end

  def self.description message_type
    case message_type
      when 'COMMENT' then _("Notify when a new comment was added.")
      when 'TRACKBACK' then _("Notify when a new entry talking about your entry was created.")
      when 'CHAIN' then _("Notify when you received an introduction.")
      when 'QUESTION' then _("Notify when the question status was changed.")
      when 'JOIN' then _("Notify when a user joined your group.")
      when 'LEAVE' then _("Notify when a user leaved your group.")
      when 'APPROVAL_OF_JOIN' then _("Notify when you were approved join of the group.")
      when 'DISAPPROVAL_OF_JOIN' then _("Notify when you were disapproved join of the group.")
      when 'FORCED_JOIN' then _("Notify when you were forced to join the group.")
      when 'FORCED_LEAVE' then _("Notify when you were forced to leave the group.")
    end
  end
end
