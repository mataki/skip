Then /^"([^\"]*)"が"([^\"]*)"回以上表示されていないこと$/ do |str, num|
  response.body.scan(str).size.should_not >= num.to_i
end
