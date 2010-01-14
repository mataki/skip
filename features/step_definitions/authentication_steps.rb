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

Given /^ログインIDが"(.*)"でパスワードが"(.*)"のあるユーザを作成する$/ do |id, password|
  @user = create_user(id,password)
end

Given /^"([^\"]*)"がユーザ登録する$/ do |user_id|
  create_user(user_id, 'Password1')
end

Given /^"([^\"]*)"が退職する$/ do |user_id|
  u = User.find_by_uid(user_id)
  u.status = "RETIRED"
  u.save
end

Given /^あるユーザはロックされている$/ do
  @user.locked = true
  @user.save
end

Given /^ログアウトする$/ do
  visit logout_path
end

Given /^"(.*)"でログインする$/ do |user_name|
  if @login_user
    if @login_user.name != user_name
      Given "ログアウトする"
      @login_user = perform_login(user_name)
    else
      Given %!"マイページ"にアクセスする!
    end
  else
    @login_user = perform_login(user_name)
  end
end

def create_user(id, password)
  uid = UserUid.find_by_uid(id)
  uid.destroy if uid
  u = User.new({ :name => id, :password => password, :password_confirmation => password, :reset_auth_token => nil, :email => "example#{id}@example.com" })
  u.user_uids.build(:uid => id, :uid_type => 'MASTER')
  u.build_user_access(:last_access => Time.now, :access_count => 0)
  u.save!
  u.status = "ACTIVE"
  u.save!
  u
end

def perform_login(user_name)
  user = User.find_by_name(user_name)
  Given %!"ログインページ"にアクセスする!
  Given %!"#{"ログインID"}"に"#{user.email}"と入力する!
  Given %!"#{"パスワード"}"に"#{"Password1"}"と入力する!
  Given %!"#{"ログイン"}"ボタンをクリックする!
  user
end

