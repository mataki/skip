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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::Account, '.make_accounts' do
  before do
    @account = mock_model(Admin::Account)
    FasterCSV.should_receive(:parse).and_return([['hoge']])
    Admin::Account.should_receive(:make_account).and_return(@account)
  end
  it { Admin::Account.send(:make_accounts, mock('mock')).should == ([@account]) }
end

describe Admin::Account, '.make_account' do
  before do
    @email = "yamada@example.com"
    @password = "password"
    @fullname = "山田 太郎"
    @job_title = "経理"
  end
  describe '既存のレコードがある場合' do
    before do
      account = create_account
      @line = [account.code, @fullname, @job_title, @email, @password]
      @account = Admin::Account.send(:make_account, @line)
    end
    it '新規レコードではないこと' do
      @account.new_record?.should_not be_true
    end
    it 'emailが引数で渡した値になっていること' do
      @account.email.should == @email
    end
    it 'passwordが引数で渡した値になっていること' do
      @account.password.should == @password
    end
    it 'password_confirmationが引数で渡した値になっていること' do
      @account.password_confirmation.should == @password
    end
    it 'fullnameが引数で渡した値になっていること' do
      @account.name.should ==  @fullname
    end
    it 'sectionが引数で渡した値になっていること' do
      @account.section == @job_title
    end
  end
  describe '既存のレコードがない場合' do
    before do
      @line = ["999999", @fullname, @job_title, @email, @password]
      @account = Admin::Account.send(:make_account, @line)
    end
    it '新規レコードであること' do
      @account.new_record?.should be_true
    end
    it 'emailが引数で渡した値になっていること' do
      @account.email.should == @email
    end
    it 'passwordが引数で渡した値になっていること' do
      @account.password.should == @password
    end
    it 'password_confirmationが引数で渡した値になっていること' do
      @account.password_confirmation == @password
    end
  end
end
