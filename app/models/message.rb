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

class Message < ActiveRecord::Base

  MESSAGE_TYPES = {
    "COMMENT"      => { :name => N_("New Comment"), :icon_name => 'comments'},
    "CHAIN"        => { :name => N_("New Introduction"), :icon_name => 'user_comment'},
    "TRACKBACK"    => { :name => N_("New Trackback"), :icon_name => 'report_go'},
    "QUESTION"     => { :name => N_("New Change of Question Status"), :icon_name => 'tick' },
    "JOIN"         => { :name => N_("Join"), :icon_name => "group_add"},
    "FORCED_JOIN"  => { :name => N_("Forced join"), :icon_name => "group_add"},
    "APPROVAL"     => { :name => N_("Approval"), :icon_name => "group_add"},
    "LEAVE"        => { :name => N_("Leave"), :icon_name => "group_delete"},
    "FORCED_LEAVE" => { :name => N_("Forced leave"), :icon_name => "group_delete"}
  }

  # FIXME: 保存時にメッセージを国際化しているので、登録した人の言語でメッセージが登録され、実際に見るひとの言語でないものの可能性がある
  def self.save_message(message_type, user_id, link_url, message)
    unless find_by_link_url_and_user_id_and_message_type(link_url,user_id, message_type)
      create :user_id => user_id, :message_type => message_type, :message => message, :link_url => link_url
    end
  end

  def self.get_message_array_by_user_id(user_id)
    find_all_by_user_id(user_id).map do |message|
      { :message => message.message, :message_type => message.message_type, :link_url => message.link_url }
    end
  end
end
