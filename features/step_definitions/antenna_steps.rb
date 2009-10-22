When /^"([^\"]*)"という新着通知を追加する$/ do |antenna_name|
  fill_in "新着通知の追加", :with => antenna_name
  click_button "追加"
end

Given /^新着通知を作成バッチを実行する$/ do
  BatchMakeUserReadings.execution
end
