# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008  TIS Inc.
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
require File.dirname(__FILE__) + '/../../lib/account_access'

describe AccountAccess, 'がアカウント情報を返すとき' do
  it 'は正しいユーザコードとパスワードが指定されていること' do
    Account.should_receive(:find_by_code_and_crypted_password).with('123456', Account.encrypt('passwd')).and_return({ "code" => '123456' , "name" => "山田　太郎", "section" => '', "email" => '123456@hoge.jp' })
    AccountAccess.auth('123456', 'passwd').should == { "code" => '123456' , "name" => "山田　太郎", "section" => '', "email" => '123456@hoge.jp' }
  end
end

describe AccountAccess, 'がエラーメッセージを返すとき' do
  it 'はDBに存在しないユーザコードとパスワードが指定されていること' do
    Account.should_receive(:find_by_code_and_crypted_password).and_return(nil)
    lambda { AccountAccess.auth('123456', 'passwd') }.should raise_error(AccountAccess::AccountAccessException)
  end
end

describe AccountAccess, 'で入力された古いパスワードが違うとき' do
  before(:each) do
    Account.should_receive(:find_by_code_and_crypted_password).and_return(nil)
  end
  it 'はAccountにold_passwordが間違っている旨を表すエラーを設定して返すこと' do
    AccountAccess.change_password('111111', {}).errors[:old_password].should_not be_blank
  end
end

describe AccountAccess, 'で入力された古いパスワードが正しいとき' do
  fixtures :accounts
  before(:each) do
    Account.should_receive(:find_by_code_and_crypted_password).and_return(accounts(:a_account))
    @before_password = accounts(:a_account).crypted_password
  end
  describe AccountAccess, 'で入力された新しいパスワードが4文字未満のとき' do
    it 'はAccountにpasswordの入力文字数が足りない旨を表すエラーを設定して返すこと' do
      AccountAccess.change_password('111111', {:old_password => 'hoge', :password => '123', :password_confirmation => '123'}).should have(1).errors_on(:password)
    end
    it 'はAccountを保存しないこと' do
      AccountAccess.change_password('111111', {:old_password => 'hoge', :password => '123', :password_confirmation => '123'})
      after_password = Account.find_by_code('111111').crypted_password
      after_password.should == @before_password
    end
  end

  describe AccountAccess, 'で入力された新しいパスワードが正しいとき' do
    it 'はAccountを保存する' do
      AccountAccess.change_password('111111', {:old_password => 'hoge', :password => '1234', :password_confirmation => '1234'})
      after_password = Account.find_by_code('111111').crypted_password
      after_password.should_not == @before_password
    end
  end
end
