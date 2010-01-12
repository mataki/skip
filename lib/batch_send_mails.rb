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

require File.expand_path(File.dirname(__FILE__) + "/batch_base")

class BatchSendMails < BatchBase
  include SystemMessagesHelper
  def self.execute options
    sender = self.new
    sender.send_message
  end

  def send_message
    SystemMessage.unsents.limit(10).ascend_by_id.all(:select => 'system_messages.*, user_message_unsubscribes.id as user_message_unsubscribe_id').each do |system_message|
      if system_message.user_message_unsubscribe_id.nil?
        user = system_message.user
        if user.retired?
          system_message.update_attribute :send_flag, true
          next
        end

        system_message_data = system_message_data(system_message, user)
        unless system_message_data
          system_message.update_attribute :send_flag, true
          next
        end

        link_url = system_message_data[:url]
        message_manage_url = url_for :controller => "/mypage", :action => "manage", :menu => :manage_message

        begin
          UserMailer::AR.deliver_sent_message(user.email, link_url, system_message_data[:message], message_manage_url)
          system_message.update_attribute :send_flag, true
        rescue => e
          self.class.log_error "failed send message [id]: #{e}"
          e.backtrace.each { |line| self.class.log_error line }
        end
      else
        system_message.update_attribute :send_flag, true
      end
    end
  end
end

BatchSendMails.execution unless RAILS_ENV == 'test'
