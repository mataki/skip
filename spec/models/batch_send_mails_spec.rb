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
require File.dirname(__FILE__) + '/../../lib/batch_make_user_readings'

describe BatchSendMails, "Mailsテーブルに未送信メールがあるとき" do
    fixtures :mails
    before(:each) do
      ActionMailer::Base.deliveries.clear
    end

  describe BatchSendMails, "ユーザが退職しておらずエントリがある場合" do
    before(:each) do
      user = mock_model(User)
      user.stub!(:retired).and_return(false)
      user.stub!(:name).and_return("hoge")
      User.should_receive(:find).and_return(user)

      board_entry = mock_model(BoardEntry)
      board_entry.stub!(:id).and_return(1)
      board_entry.stub!(:title).and_return("hoge")
      BoardEntry.should_receive(:find).and_return(board_entry)

      mail = mails(:a_mail)
      Mail.should_receive(:find).and_return([mail])
    end
    it "メールが送信される" do
      BatchSendMails.send_notice
      ActionMailer::Base.deliveries.first.body.should match(/page\/1/m)
    end
  end

  describe BatchSendMails, "ユーザが退職している場合" do
    before(:each) do
      user = mock_model(User)
      user.stub!(:retired).and_return(true)
      User.should_receive(:find).and_return(user)

      mail = mails(:a_mail)
      mail.should_receive(:update_attribute).with(:send_flag,true)
      Mail.should_receive(:find).and_return([mail])
    end
    it "レコードが送信済みとなり、メールが送信されない" do
      BatchSendMails.send_notice
      ActionMailer::Base.deliveries.size.should == 0
    end
  end

  describe BatchSendMails, "エントリがない場合" do
    before(:each) do
      user = mock_model(User)
      user.stub!(:retired).and_return(false)
      user.stub!(:name).and_return("hoge")
      User.should_receive(:find).and_return(user)

      BoardEntry.should_receive(:find).and_return(nil)

      mail = mails(:a_mail)
      Mail.should_receive(:find).and_return([mail])
    end
    it "メールが送信されない" do
      BatchSendMails.send_notice
      ActionMailer::Base.deliveries.size.should == 0
    end
  end
end
