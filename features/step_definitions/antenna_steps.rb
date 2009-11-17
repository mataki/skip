When /^新着時に通知リンクをクリックした状態にする$/ do
  pending
end

Given /^新着通知を作成バッチを実行する$/ do
  BatchMakeUserReadings.execution
end
