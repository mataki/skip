When /^"([^\"]*)"という新着通知を追加する$/ do |antenna_name|
  fill_in "新着通知の追加", :with => antenna_name
  click_button "追加"
end
