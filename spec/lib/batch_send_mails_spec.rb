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

require File.dirname(__FILE__) + '/../spec_helper'

describe BatchSendMails, '#send_notice' do
  before do
    @sender = BatchSendMails.new
  end
  describe BatchSendMails, "Mailsテーブルに未送信メールがあるとき" do
    before do
      @mail = stub_model(Mail, :to_address => "to_address@example.com")
      Mail.stub!(:find).and_return([@mail])
      ActionMailer::Base.deliveries.clear
    end
    describe '送信元ユーザ(from_user_id)が退職している場合' do
      before do
        user = stub_model(User)
        user.should_receive(:retired?).and_return(true)
        User.should_receive(:find).and_return(user)
        to_user = stub_model(User)
        to_user_profile = stub_model(UserProfile)
        to_user_profile.stub!(:user).and_return(to_user)
        UserProfile.stub!(:find_by_email).and_return(to_user_profile)
      end
      it '対象のMailsテーブルのレコードが送信済みとなること' do
        @mail.should_receive(:update_attribute).with(:send_flag,true)
        @sender.send_notice
      end
      it '送信元ユーザからのメールが送信されないこと' do
        @mail.stub!(:update_attribute).with(:send_flag,true)
        ActionMailer::Base.deliveries.size.should == 0
        @sender.send_notice
      end
    end
    describe '送信元ユーザ(from_user_id)が退職していない場合' do
      before do
        @user = stub_model(User)
        @user.stub!(:retired?).and_return(false)
        User.stub!(:find).and_return(@user)
      end
      describe '送信先アドレスが見つからない場合' do
        before do
          UserProfile.stub!(:find_by_email).and_return(nil)
        end
        it "対象のMailsテーブルのレコードが送信済みになること" do
          @mail.should_receive(:update_attribute).with(:send_flag,true)
          @sender.send_notice
        end
        it '送信元ユーザからのメールが送信されないこと' do
          @mail.stub!(:update_attribute).with(:send_flag,true)
          ActionMailer::Base.deliveries.size.should == 0
          @sender.send_notice
        end
      end
      describe '送信先アドレスが見つかる場合' do
        describe '送信先ユーザ(to_address)が退職している場合' do
          before do
            to_user = stub_model(User)
            to_user.stub!(:retired?).and_return(true)
            to_user_profile = stub_model(UserProfile)
            to_user_profile.stub!(:user).and_return(to_user)
            UserProfile.stub!(:find_by_email).and_return(to_user_profile)
          end
          it '対象のMailsテーブルのレコードが送信済みとなること' do
            @mail.should_receive(:update_attribute).with(:send_flag,true)
            @sender.send_notice
          end
          it '送信先ユーザへメールが送信されないこと' do
            @mail.stub!(:update_attribute).with(:send_flag,true)
            ActionMailer::Base.deliveries.size.should == 0
            @sender.send_notice
          end
        end
        describe '送信先ユーザ(to_address)が退職していない場合' do
          before do
            to_user = stub_model(User)
            to_user.stub!(:retired?).and_return(false)
            to_user_profile = stub_model(UserProfile)
            to_user_profile.stub!(:user).and_return(to_user)
            UserProfile.stub!(:find_by_email).and_return(to_user_profile)
          end
          describe BatchSendMails, "送信元ユーザの記事がある場合" do
            before do
              @board_entry = mock_model(BoardEntry, :id => 1, :title => "title")
              BoardEntry.should_receive(:find).and_return(@board_entry)
            end
            it "メールが送信される" do
              UserMailer.should_receive(:deliver_sent_contact).with(@mail.to_address, @user.name, "#{Admin::Setting.protocol_by_initial_settings_default}#{Admin::Setting.host_and_port_by_initial_settings_default}/page/1", @board_entry.title)
              @sender.send_notice
            end
          end
          describe BatchSendMails, "送信元ユーザの記事がない場合" do
            before do
              BoardEntry.should_receive(:find).and_return(nil)
            end
            it "メールが送信されない" do
              @sender.send_notice
              ActionMailer::Base.deliveries.size.should == 0
            end
          end
        end

      end
    end
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
          @user_profile = stub_model(UserProfile, :email => SkipFaker.email)
          @user = stub_model(User, :retired? => false, :user_profile => @user_profile)
          User.should_receive(:find).and_return(@user)
          UserMailer.stub!(:deliver_sent_message)
        end
        it 'messagesテーブルの対象レコードが送信済みとなること' do
          Message.should_receive(:find).and_return([@message])
          @message.should_receive(:update_attribute).with(:send_flag, true)
          @sender.send_message
        end
        it 'メールが送信されること' do
          UserMailer.should_receive(:deliver_sent_message).with(@user_profile.email, "#{Admin::Setting.protocol_by_initial_settings_default}#{Admin::Setting.host_and_port_by_initial_settings_default + @message.link_url}", @message.message, "#{Admin::Setting.protocol_by_initial_settings_default}#{Admin::Setting.host_and_port_by_initial_settings_default}/mypage/manage?menu=manage_message")
          @sender.send_message
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
