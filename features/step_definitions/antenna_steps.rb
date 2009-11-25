When /^新着時に通知リンクをクリックした状態にする$/ do
  pending
end

Given /^新着通知を作成バッチを実行する$/ do
  BatchMakeUserReadings.execution
end

Given /^"([^\"]*)"で"([^\"]*)"を新着通知に追加する$/ do |from, to|
  Given %!"#{from}"がユーザ登録する!  unless User.find_by_uid(from)
  Given %!"#{to}"がユーザ登録する!  unless User.find_by_uid(to)
  Given %!"#{from}"でログインする!
  Given %!"#{to}ユーザのプロフィールページ"にアクセスする!
  Given %!"新着時に通知"リンクをクリックする!
end
