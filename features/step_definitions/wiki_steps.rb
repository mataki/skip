Then /ページのタブメニューが表示されていること/ do
  Then %q|"内容"と表示されていること|
  Then %q|"履歴"と表示されていること|
  Then %q|"検索"と表示されていること|
end

Then /^ペンディング"([^\"]*)"$/ do |msg|
  pending
end
