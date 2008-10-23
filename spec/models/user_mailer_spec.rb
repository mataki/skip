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

describe UserMailer do
  include ActionController::UrlWriter
  before do
    UserMailer.new
  end
  it "@@site_urlが正しく設定されていること" do
    UserMailer.site_url.should == root_url(:host => INITIAL_SETTINGS['host_and_port'])
  end
  it "@@system_mail_addrが正しく設定されていること" do
    UserMailer.system_mail_addr.should == Admin::Setting.contact_addr
  end
  it "@@fromが正しく設定されていること" do
    UserMailer.from.should == "#{UserMailer.send(:base64, Admin::Setting.abbr_app_title)}<#{UserMailer.system_mail_addr}>"
  end
  it "@@footerが正しく設定されていること" do
    UserMailer.footer.should == "----\n#{UserMailer.system_mail_addr}\n#{UserMailer.site_url}"
  end

  UserMailer.class_eval{
    cattr_accessor :site_url, :system_mail_addr, :from, :footer
  }
end

describe UserMailer, "#smtp_settings" do
  before do
    Admin::Setting.stub!(:smtp_settings_address).and_return("address")
    Admin::Setting.stub!(:smtp_settings_domain).and_return("domain")
    Admin::Setting.stub!(:smtp_settings_port).and_return("port")
    Admin::Setting.stub!(:smtp_settings_user_name).and_return("user_name")
    Admin::Setting.stub!(:smtp_settings_password).and_return("password")
    Admin::Setting.stub!(:smtp_settings_authentication).and_return("authentication")
  end
  it "DBの内容を返すこと" do
    UserMailer.smtp_settings[:address].should == "address"
    UserMailer.smtp_settings[:port].should == "port"
    UserMailer.smtp_settings[:domain].should == "domain"
    UserMailer.smtp_settings[:user_name].should == "user_name"
    UserMailer.smtp_settings[:password].should == "password"
    UserMailer.smtp_settings[:authentication].should == "authentication"
  end
end
