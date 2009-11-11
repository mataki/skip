Then /^"([^\"]*)"と表示されること$/ do |text|
  Then %Q(I should see "#{text}")
end

When /^"([^\"]*)"リンクを"([^\"]*)"クリックする$/ do |link, method|
  method = method.blank? ? :get : method.downcase.to_sym
  click_link(link, :method => method)
end

Given /^"([^\"]*)"にアクセスする$/ do |page_name|
  Given "I am on #{page_name}"
end

Then /^"([^\"]*)"と表示されてること$/ do |text|
  Then %Q(I should see "#{text}")
end

Then /^"([^\"]*)"が選択されていること$/ do |label|
  Then %Q(the "#{label}" checkbox should be checked)
end

When /^再読み込みする$/ do
  visit request.request_uri
end

When /^デバッガで止める$/ do
  require 'ruby-debug'
  debugger
end
