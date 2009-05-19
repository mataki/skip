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
    @sender.stub!(:send_notice)
    @sender.stub!(:send_message)
    @sender.stub!(:send_cleaning_notification)
  end
  it 'noticeメールの送信処理がおこなわれること' do
    @sender.should_receive(:send_notice)
    BatchSendMails.execute []
  end
  it 'messageメールの送信処理がおこなわれること' do
    @sender.should_receive(:send_message)
    BatchSendMails.execute []
  end
end

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
        User.stub!(:find_by_email).and_return(to_user)
      end
      it '対象のMailsテーブルのレコードが送信済みとなること' do
        @mail.should_receive(:update_attribute).with(:send_flag,true)
        @sender.send_notice
      end
      it '送信元ユーザからのメールが送信されないこと' do
        @mail.stub!(:update_attribute).with(:send_flag,true)
        lambda do
          @sender.send_notice
        end.should_not change(ActionMailer::Base.deliveries, :size)
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
          User.stub!(:find_by_email).and_return(nil)
          @mail.stub!(:update_attribute)
        end
        it "対象のMailsテーブルのレコードが送信済みになること" do
          @mail.should_receive(:update_attribute).with(:send_flag,true)
          @sender.send_notice
        end
        it '送信元ユーザからのメールが送信されないこと' do
          lambda do
            @sender.send_notice
          end.should_not change(ActionMailer::Base.deliveries, :size)
        end
      end
      describe '送信先アドレスが見つかる場合' do
        describe '送信先ユーザ(to_address)が存在していない場合' do
          before do
            @sender.stub!(:retired_check_to_address).and_return(nil)
            @mail.stub!(:update_attribute)
          end
          it '対象のMailsテーブルのレコードが送信済みとなること' do
            @mail.should_receive(:update_attribute).with(:send_flag,true)
            @sender.send_notice
          end
          it '送信先ユーザへメールが送信されないこと' do
            lambda do
              @sender.send_notice
            end.should_not change(ActionMailer::Base.deliveries, :size)
          end
        end
        describe '送信先ユーザ(to_address)が退職していない場合' do
          before do
            @sender.stub!(:retired_check_to_address).and_return(@mail.to_address)
          end
          describe BatchSendMails, "送信元ユーザの記事がある場合" do
            before do
              @board_entry = mock_model(BoardEntry, :id => 1, :title => "title")
              BoardEntry.should_receive(:find).and_return(@board_entry)
            end
            it "メールが送信される" do
              lambda do
                @sender.send_notice
              end.should change(ActionMailer::Base.deliveries, :size).to(1)
            end
          end
          describe BatchSendMails, "送信元ユーザの記事がない場合" do
            before do
              BoardEntry.should_receive(:find).and_return(nil)
            end
            it "メールが送信されない" do
              lambda do
                @sender.send_notice
              end.should_not change(ActionMailer::Base.deliveries, :size).to(0)
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
          end.should change(ActionMailer::Base.deliveries, :size).to(1)
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

describe BatchSendMails, "#retired_check_to_address" do
  before do
    @sender = BatchSendMails.new
    User.stub!(:find_by_email).and_return(nil)
    User.stub!(:find_by_email).with('a_user@example.com').and_return(stub_model(User, :retired? => false))
    User.stub!(:find_by_email).with('b_user@example.com').and_return(stub_model(User, :retired? => false))
    User.stub!(:find_by_email).with('retired_user@example.com').and_return(stub_model(User, :retired? => true))
  end
  describe "一つの存在するアドレスの場合" do
    it "存在するアドレスを返す" do
      to_address = 'a_user@example.com'
      @sender.retired_check_to_address(to_address).should == to_address
    end
  end
  describe "複数の存在するアドレスの場合" do
    it "複数のアドレスを返す" do
      to_address = "a_user@example.com,b_user@example.com"
      @sender.retired_check_to_address(to_address).should == to_address
    end
  end
  describe "一つの存在しないアドレスの場合" do
    it "nilを返す" do
      to_address = "no_user@example.com"
      @sender.retired_check_to_address(to_address).should be_nil
    end
  end
  describe "存在するが退職者のアドレスの場合" do
    it "nilを返す" do
      to_address = "retired_user@example.com"
      @sender.retired_check_to_address(to_address).should be_nil
    end
  end
  describe "複数の中に存在しないアドレスがある場合" do
    it "存在するアドレスのみを返す" do
      to_address = "a_user@example.com,no_user@example.com,b_user@example.com"
      @sender.retired_check_to_address(to_address).should == "a_user@example.com,b_user@example.com"
    end
  end
end
