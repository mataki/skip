Then /^flashメッセージに"([^\"]*)"と表示されていること$/ do |message|
  response.body.should =~ /#{Regexp.escape(message.to_json)}/m
end

Then /^flashメッセージに"([^\"]*)"と表示されていないこと$/ do |message|
  response.body.should_not =~ /#{Regexp.escape(message.to_json)}/m
end
