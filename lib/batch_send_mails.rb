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
  def self.execute options
    sender = self.new
    sender.send_message
  end

  def send_message
    Message.find(:all,
                 :select =>'messages.*, user_message_unsubscribes.id as user_message_unsubscribe_id',
                 :conditions => "send_flag = false",
                 :order => 'messages.id asc',
                 :limit => 10,
                 :joins => 'LEFT JOIN user_message_unsubscribes USING(user_id,message_type)').each do |message|
      if message.user_message_unsubscribe_id.nil?
        user = User.find(:first, :conditions => ["id = ?", message.user_id])
        if user.retired?
          message.update_attribute :send_flag, true
          next
        end
        #TODO 後日、message.link_urlをそのままセットする形にする。
        # http://dev.openskip.org/redmine/issues/show/516 の修正に伴う後方互換のため1.1時点では従来通りの挙動を残してある。
        link_url = message.link_url =~ /^https?.*/ ? message.link_url : root_url.chop + message.link_url
        message_manage_url = url_for :controller => "/mypage", :action => "manage", :menu => :manage_message

        begin
          UserMailer::AR.deliver_sent_message(user.email, link_url, message.message, message_manage_url)
          message.update_attribute :send_flag, true
        rescue => e
          self.class.log_error "failed send message [id]: #{e}"
          e.backtrace.each { |line| self.class.log_error line }
        end
      else
        message.update_attribute :send_flag, true
      end
    end
  end
end

BatchSendMails.execution unless RAILS_ENV == 'test'
