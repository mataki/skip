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

require File.dirname(__FILE__) + '/../spec_helper'

describe BatchSendCleaningNotification, '#.execute' do
  before do
    @sender = BatchSendCleaningNotification.new
    BatchSendCleaningNotification.should_receive(:new).and_return(@sender)
    @sender.stub!(:send_cleaning_notification)
  end
  it 'クリーニング依頼メールの送信処理がおこなわれること' do
    @sender.should_receive(:send_cleaning_notification)
    BatchSendCleaningNotification.execute []
  end
end

describe BatchSendCleaningNotification, '#send_cleaning_notification' do
  before do
    @sender = BatchSendCleaningNotification.new
    @sender.stub!(:cleaning_notification_to_addresses).and_return('email1, email2')
    ActionMailer::Base.deliveries.clear
  end
  describe 'クリーニング依頼メールを送信する設定の場合' do
    before do
      Admin::Setting.should_receive(:enable_user_cleaning_notification).and_return(true)
    end
    describe '送信間隔が3ヶ月の場合' do
      before do
        Admin::Setting.should_receive(:user_cleaning_notification_interval).and_return(3)
      end
      describe '実行日時が3/1の場合' do
        before do
          @now = Time.local(2009, 3, 1)
          Time.stub!(:now).and_return(@now)
        end
        it 'メール送信されること' do
          lambda do
            @sender.send_cleaning_notification
          end.should change(ActionMailer::Base.deliveries, :size).to(1)
        end
      end
      describe '実行日時が3/2の場合' do
        before do
          @now = Time.local(2009, 3, 2)
          Time.stub!(:now).and_return(@now)
        end
        it 'メール送信されないこと' do
          lambda do
            @sender.send_cleaning_notification
          end.should_not change(ActionMailer::Base.deliveries, :size)
        end
      end
      describe '実行日時が4/1の場合' do
        before do
          @now = Time.local(2009, 4, 1)
          Time.stub!(:now).and_return(@now)
        end
        it 'メール送信されないこと' do
          lambda do
            @sender.send_cleaning_notification
          end.should_not change(ActionMailer::Base.deliveries, :size)
        end
      end
      describe '実行日時が6/1の場合' do
        before do
          @now = Time.local(2009, 6, 1)
          Time.stub!(:now).and_return(@now)
        end
        it 'メール送信されること' do
          lambda do
            @sender.send_cleaning_notification
          end.should change(ActionMailer::Base.deliveries, :size).to(1)
        end
      end
    end
    describe '送信間隔が6ヶ月の場合' do
      before do
        Admin::Setting.should_receive(:user_cleaning_notification_interval).and_return(6)
      end
      describe '実行日時が3/1の場合' do
        before do
          @now = Time.local(2009, 3, 1)
          Time.stub!(:now).and_return(@now)
        end
        it 'メール送信されないこと' do
          lambda do
            @sender.send_cleaning_notification
          end.should_not change(ActionMailer::Base.deliveries, :size)
        end
      end
      describe '実行日時が4/1の場合' do
        before do
          @now = Time.local(2009, 4, 1)
          Time.stub!(:now).and_return(@now)
        end
        it 'メール送信されないこと' do
          lambda do
            @sender.send_cleaning_notification
          end.should_not change(ActionMailer::Base.deliveries, :size)
        end
      end
      describe '実行日時が6/1の場合' do
        before do
          @now = Time.local(2009, 6, 1)
          Time.stub!(:now).and_return(@now)
        end
        it 'メール送信されること' do
          lambda do
            @sender.send_cleaning_notification
          end.should change(ActionMailer::Base.deliveries, :size).to(1)
        end
      end
      describe '実行日時が6/2の場合' do
        before do
          @now = Time.local(2009, 6, 2)
          Time.stub!(:now).and_return(@now)
        end
        it 'メール送信されないこと' do
          lambda do
            @sender.send_cleaning_notification
          end.should_not change(ActionMailer::Base.deliveries, :size)
        end
      end
    end
  end
  describe 'クリーニング依頼メールを送信しない設定の場合' do
    before do
      Admin::Setting.should_receive(:enable_user_cleaning_notification).and_return(false)
    end
    it 'メール送信されないこと' do
      lambda do
        @sender.send_cleaning_notification
      end.should_not change(ActionMailer::Base.deliveries, :size)
    end
  end
end
