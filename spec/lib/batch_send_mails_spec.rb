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

require File.dirname(__FILE__) + '/../spec_helper'

describe BatchSendMails, '#.execute' do
  before do
    @sender = BatchSendMails.new
    BatchSendMails.should_receive(:new).and_return(@sender)
    @sender.stub!(:send_message)
    @sender.stub!(:send_cleaning_notification)
  end
  it 'messageメールの送信処理がおこなわれること' do
    @sender.should_receive(:send_message)
    BatchSendMails.execute []
  end
end

describe BatchSendMails, '#send_message' do
  before do
    @sender = BatchSendMails.new
  end
  describe 'messagesテーブルに未送信メールがある場合' do
    before do
      @message = stub_model(Message, :send_flag => false, :link_url => "/page/1")
      ActionMailer::Base.deliveries.clear
    end
    describe '関連するuser_message_unsubscribesテーブルが存在する場合' do
      before do
        @message.stub!(:user_message_unsubscribe_id).and_return(SkipFaker.rand_num)
        @message.stub!(:update_attribute)
        Message.stub!(:find).and_return([@message])
      end
      it 'messagesテーブルの対象レコードが送信済みとなること' do
        @message.should_receive(:update_attribute).with(:send_flag, true)
        Message.should_receive(:find).and_return([@message])
        @sender.send_message
      end
      it 'メールが送信されないこと' do
        lambda do
          @sender.send_message
        end.should_not change(ActionMailer::Base.deliveries, :size)
      end
    end
    describe '関連するuser_message_unsubscribesテーブルが存在しない場合' do
      before do
        @message.stub!(:user_message_unsubscribe_id).and_return(nil)
        @message.stub!(:update_attribute)
        Message.stub!(:find).and_return([@message])
      end
      describe 'ユーザが退職していない場合' do
        before do
          @user = stub_model(User, :retired? => false, :email => SkipFaker.email)
          User.should_receive(:find).and_return(@user)
        end
        it 'messagesテーブルの対象レコードが送信済みとなること' do
          Message.should_receive(:find).and_return([@message])
          @message.should_receive(:update_attribute).with(:send_flag, true)
          @sender.send_message
        end
        it 'メールが送信されること' do
          lambda do
            @sender.send_message
          end.should change(Email, :count).to(1)
        end
      end
      describe 'ユーザが退職している場合' do
        before do
          user = stub_model(User)
          user.should_receive(:retired?).and_return(true)
          User.should_receive(:find).and_return(user)
        end
        it 'messagesテーブルの対象レコードが送信済みとなること' do
          @message.should_receive(:update_attribute).with(:send_flag, true)
          Message.should_receive(:find).and_return([@message])
          @sender.send_message
        end
        it 'メールが送信されないこと' do
          lambda do
            @sender.send_message
          end.should_not change(ActionMailer::Base.deliveries, :size)
        end
      end
    end
  end
end
