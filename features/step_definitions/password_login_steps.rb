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

Given /ログインページを表示している/ do
  visit "/platform"
end

Given /^ログインIDが"(.*)"でパスワードが"(.*)"のユーザを作成する$/ do |id, password|
  u = User.new({ :name => 'ほげ ほげ', :password => password, :password_confirmation => password, :reset_auth_token => nil, :email => "a_user@example.com" })
  u.user_uids.build(:uid => id, :uid_type => 'MASTER')
  u.build_user_access(:last_access => Time.now, :access_count => 0)
  u.save!
  u.status = "ACTIVE"
  u.save!
end

