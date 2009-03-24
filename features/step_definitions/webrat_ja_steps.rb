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

# Commonly used webrat steps
# http://github.com/brynary/webrat

When /言語は"(.*)"/ do |lang|
  header("ACCEPT_LANGUAGE", lang)
end

When /^"(.*)"ボタンをクリックする$/ do |button|
  click_button(button)
end

When /^"(.*)"リンクをクリックする$/ do |link|
  click_link(link)
end

When /再読み込みする/ do
  visit request.request_uri
end

When /^"(.*)"に"(.*)"と入力する$/ do |field, value|
  fill_in(field, :with => value)
end

# opposite order from Engilsh one(original)
When /^"(.*)"から"(.*)"を選択$/ do |field, value|
  selects(value, :from => field)
end

When /^"(.*)"をチェックする$/ do |field|
  checks(field)
end

When /^"(.*)"のチェックを外す$/ do |field|
  unchecks(field)
end

When /^"(.*)"を選択する$/ do |field|
  chooses(field)
end

# opposite order from Engilsh one(original)
When /^"(.*)"としてをファイル"(.*)"を添付する$/ do |field, path|
  attaches_file(field, path)
end

Then /^"(.*)"と表示されていること$/ do |text|
  response.body.should =~ /#{Regexp.escape(text)}/m
end

Then /^"(.*)"と表示されていないこと$/ do |text|
  response.body.should_not =~ /#{text}/m
end

Then /^"(.*)"がチェックされていること$/ do |label|
  field_labeled(label).should be_checked
end

Then %r!デバッグのためページを確認する! do
  save_and_open_page
end

When /^"(.*)"としてファイル"(.*)"を添付する$/ do |field, path|
  attach_file(field, path)
end
