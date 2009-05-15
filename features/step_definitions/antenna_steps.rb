Given /^全体からのユーザ検索画面を表示する$/ do
  visit url_for(:controller => 'users')
end

Given /^"(.*)"ユーザのプロフィールページを表示する$/ do |user|
  visit url_for(:controller => "user", :action => "show", :uid => user)
end

When /^"([^\"]*)"というアンテナを追加する$/ do |antenna_name|
  fill_in "アンテナの追加", :with => antenna_name
  click_button "保存"
end
