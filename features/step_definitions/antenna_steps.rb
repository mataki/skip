When /^"([^\"]*)"というアンテナを追加する$/ do |antenna_name|
  fill_in "アンテナの追加", :with => antenna_name
  click_button "追加"
end
