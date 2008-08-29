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

describe Account, "何も指定していない場合エラーが設定される" do
  before(:each) do
    @account = Account.new
  end

  it { @account.should_not be_valid }

  it { @account.should have(2).errors_on(:code) }
  it { @account.should have(1).errors_on(:name) }
  it { @account.should have(2).errors_on(:password) }
end

describe Account, "#code" do
  before do
    @account = new_account
  end
  describe "記号(.)が含まれている場合" do
    before do
      @account.code = "hoge.hoge"
      @account.save
    end
    it "バリデーションエラーになること" do
      @account.should_not be_valid
    end
  end
  describe "記号(_)が含まれている場合" do
    before do
      @account.code = "hoge_hoge"
      @account.save
    end
    it "保存できること" do
      @account.should be_valid
    end
  end
end

describe Account, "適切な値が与えられた場合保存できる" do
  before(:each) do
    @account = new_account
  end

  it { @account.should be_valid }

  it "保存する際はパスワードが暗号化される" do
    @account.save.should be_true
    @account.crypted_password.should == Account.encrypt("hoge")
  end

  it "パスワード以外の変更で再度保存される場合はパスワードは変更されない" do
    @account.save
    @account = Account.find_by_code("hoge")

    @account.should_not_receive(:crypted_password=)
    @account.name = 'fuga'
    @account.send(:password_required?).should be_false
    @account.save
  end
end

describe Account, ".create_with_identity_url" do
  before do
    @identity_url = "http://test.com/identity"
    @params = { :code => 'hoge', :email => 'hoge@hoge.jp', :name => "ほげ ふが" }
    lambda do
      @account = Account.create_with_identity_url(@identity_url, @params)
    end.should change(Account, :count).by(1)
  end

  it { @account.should be_valid }
  it { @account.should be_is_a(Account) }
  it { @account.openid_identifiers.should_not be_nil }
  it { @account.openid_identifiers.map{|i| i.url}.should be_include(@identity_url) }
end

private
def new_account options = {}
  Account.new({ :password => "hoge", :password_confirmation => "hoge",
                :email => "hoge@hoge.com", :name => "hoge",
                :code => "hoge" }.update(options) )
end
