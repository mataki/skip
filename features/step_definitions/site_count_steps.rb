Given /^現在の統計データを退避する$/ do
  @site_count_was = SiteCount.create_data
end

Given /^統計データを取得する$/ do
  @site_count_now = SiteCount.create_data
end

Then /^"([^\"]*)"が"([^\"]*)"変化すること$/ do |column, value|
  (@site_count_now.send(column) - @site_count_was.send(column)).should == value.to_i
end
