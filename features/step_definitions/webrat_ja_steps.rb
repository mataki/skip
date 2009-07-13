# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
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

sel = %q|"([^"]*)"| #"

def response_body_text(source = response.body)
  Nokogiri::HTML(source).text
end

When /"(.*)"にアクセスする/ do |page_name|
  visit path_to(page_name)
end

When /言語は"(.*)"/ do |lang|
  header("ACCEPT_LANGUAGE", lang)
end

When /^"(.*)"ボタンをクリックする$/ do |button|
  click_button(button)
end

When(/^"([^"]*)"リンクを(.*)クリックする$/)do |link, method|
  method = method.blank? ? :get : method.downcase.to_sym
  click_link(link, :method => method)
end

When /^"(.*)"中の"(.*)"リンクをクリックする$/ do |selector, link|
  click_link_within(selector, link)
end

When(/^テーブル#{sel}の"(\d+)"行目の#{sel}リンクをクリックする/) do |cls, nth, link|
  selector = "table.#{cls} tbody tr:nth(#{nth})"
  click_link_within(selector, link)
end

When /^再読み込みする$/ do
  visit request.request_uri
end

When /^"(.*)"に"(.*)"と入力する$/ do |field, value|
  fill_in(field, :with => value)
end

# opposite order from Engilsh one(original)
When /^"(.*?)"から"(.*?)"を選択する$/ do |field, value|
  select(value, :from => field)
end

When /^"(.*)"をチェックする$/ do |field|
  check(field)
end

When /^"(.*)"のチェックを外す$/ do |field|
  uncheck(field)
end

When /^#{sel}を選択する$/ do |field|
  choose(field)
end

# opposite order from Engilsh one(original)
When /^"(.*)"としてファイル"(.*)"を添付する$/ do |field, path|
  attach_file(field, path)
end

Then /^"(.*)"と表示されて?い?ること$/ do |text|
  response_body_text.should =~ /#{Regexp.escape(text)}/m
end

Then /^"(.*)"と表示されていないこと$/ do |text|
  response_body_text.should_not =~ /#{Regexp.escape(text)}/m
end

Then /^"(.*)"がチェックされていること$/ do |label|
  field_labeled(label).should be_checked
end


Then /^"(.*)"が選択されていること$/ do |label|
  field_labeled(label).should be_checked
end

Then %r!デバッグのための?ページを確認する! do
  save_and_open_page
end

Then /^"(.*?)"がリンクになっていないこと$/ do |label|
  Nokogiri::HTML(response.body).search("a").select{|a| a.text == label }.should be_empty
  response_body_text.should =~ /#{Regexp.escape(label)}/m
end

When /^デバッガで止める$/ do
  require "ruby-debug"
  debugger
end

When /^"([^\"]*)"としてファイル"([^\"]*)"をContent\-Type"([^\"]*)"として添付する$/ do |field, path, content_type|
  attach_file(field, path, content_type)
end
