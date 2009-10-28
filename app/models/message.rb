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
    "COMMENT"   => { :name => N_("New Comment"), :message => N_("You recieved a comment on your entry [?]!"), :icon_name => 'comments'},
    "CHAIN"     => { :name => N_("New Introduction"), :message => N_("You received an introduction!"), :icon_name => 'user_comment'},
    "TRACKBACK" => { :name => N_("New Entry"), :message => N_("There is a new entry talking about your entry [?]!"), :icon_name => 'report_go'},
    "POSTIT"    => { :name => N_("New Bookmark"), :message => N_("New bookmark in your profile!"), :icon_name => 'tag_blue'},
    "QUESTION"  => { :name => N_("New Changeing state of Question"), :message => _('State of your question [?] is changed!'), :icon_name => 'tick' }
  }

  def self.save_message(message_type, user_id, link_url, title = nil)
    return if find_by_link_url_and_user_id_and_message_type(link_url,user_id, message_type)
    create( :user_id => user_id,
            :message_type => message_type,
            :link_url => link_url,
            # FIXME: 保存時にメッセージを国際化しているので、登録した人の言語でメッセージが登録され、実際に見るひとの言語でないものの可能性がある
            :message => title ? _(MESSAGE_TYPES[message_type][:message]).gsub('?', title) : _(MESSAGE_TYPES[message_type][:message]))
  end


  def self.get_message_array_by_user_id(user_id)
    find_all_by_user_id(user_id).map do |message|
      { :message => message.message, :message_type => message.message_type, :link_url => message.link_url }
    end
  end


end
