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

Given /^ログインIDが"(.*)"でパスワードが"(.*)"のあるユーザでログインする$/ do |id, password|
  @user = create_user(id, password)
  visit "/platform"
  fill_in("ログインID", :with => id)
  fill_in("パスワード", :with => password)
  click_button("ログイン")
end

Then /^メールが"([^\"]*)"宛に送信されていること$/ do |arg1|
  pending
end
