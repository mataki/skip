# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008 TIS Inc.
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

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

class BatchSendMails < BatchBase

  def self.execute options
    send_notice
    send_message
  end

  def self.send_notice
    Mail.find(:all, :conditions => "send_flag = false", :order => 'id asc', :limit => 30).each do |mail|
      user = User.find(:first, :conditions => ["user_uids.uid = ?", mail.from_user_id], :include => ['user_uids'])
      if user.retired?
        mail.update_attribute :send_flag, true
        next
      end
      board_entry = BoardEntry.find(:first, :conditions => ["user_id = ? and user_entry_no = ?", user.id, mail.user_entry_no])
      next unless board_entry
      entry_url = "#{ENV['SKIP_URL']}/page/#{board_entry.id}"

      begin
        UserMailer.deliver_sent_contact(mail.to_address, user.name, entry_url, board_entry.title)
        mail.update_attribute :send_flag, true
      rescue
        log_error "failed send mail [id]:" + mail.id.to_s + " " + $!
      end
    end
  end

  def self.send_message
    Message.find(:all,
                 :select =>'messages.*, user_message_unsubscribes.id as user_message_unsubscribe_id',
                 :conditions => "send_flag = false",
                 :order => 'messages.id asc',
                 :limit => 10,
                 :joins => 'LEFT JOIN user_message_unsubscribes USING(user_id,message_type)').each do |message|
      if message.user_message_unsubscribe_id.nil?
        user = User.find(:first, :conditions => ["id = ?", message.user_id])
        link_url = "#{ENV['SKIP_URL']}#{message.link_url}"
        message_manage_url = "#{ENV['SKIP_URL']}/mypage/manage?menu=manage_message"
        begin
          UserMailer.deliver_sent_message(user.email, link_url, message.message, message_manage_url)
          message.update_attribute :send_flag, true
        rescue
          log_error "failed send message [id]:" + message.id.to_s + " " + $!
        end
      else
        message.update_attribute :send_flag, true
      end
    end
  end
end

BatchSendMails.execution
