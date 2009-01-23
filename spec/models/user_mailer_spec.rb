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

describe UserMailer do
  def test_sent_apply_email_confirm
    response = UserMailer.create_sent_apply_email_confirm SkipFaker.email, SkipFaker.rand_char
    assert_match /https?:\/\/.*\/$/m, response.body
  end
end

describe UserMailer, "#smtp_settings" do
  before(:all) do
    Admin::Setting.stub!(:mail_function_setting).and_return(true)
    @before_errors = ActionMailer::Base.raise_delivery_errors
    ActionMailer::Base.raise_delivery_errors = true
  end
  before do
    Admin::Setting.stub!(:smtp_settings_address).and_return("address")
    Admin::Setting.stub!(:smtp_settings_domain).and_return("domain")
    Admin::Setting.stub!(:smtp_settings_port).and_return("port")
    Admin::Setting.stub!(:smtp_settings_user_name).and_return("user_name")
    Admin::Setting.stub!(:smtp_settings_password).and_return("password")
    Admin::Setting.stub!(:smtp_settings_authentication).and_return("authentication")
    @smtp = mock('smtp')
    @smtp.stub!(:sendmail)
    Net::SMTP.stub!(:start).and_yield(@smtp)
  end
  it "Net::SMTPメソッドでDBの内容を利用して送信すること" do
    Net::SMTP.should_receive(:start).with("address", "port", "domain", "user_name", "password", "authentication").and_yield(@smtp)
    UserMailer.deliver_sent_forgot_password("test@test.com", "password")
  end
  after(:all) do
    ActionMailer::Base.delivery_method = @before_method
    ActionMailer::Base.raise_delivery_errors = @before_errors
  end
end
