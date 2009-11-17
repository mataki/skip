Given /^"([^\"]*)"で"([^\"]*)"というグループを作成する$/ do |user, gid|
  Given %!"#{user}"でログインする!
  Given %!"グループの新規作成ページ"にアクセスする!
  Given %!"#{"グループID"}"に"#{gid}"と入力する!
  Given %!"#{"名称"}"に"テストグループ"と入力する!
  Given %!"#{"説明"}"に"説明"と入力する!
  Given %!"#{"作成"}"ボタンをクリックする!
end

When /^"([^\"]*)"で"([^\"]*)"グループのサマリページを開く$/ do |user, gid|
  Given %!"#{user}"でログインする!
  visit url_for(:controller => 'group', :gid => gid, :action => 'show')
end

Given /^以下のグループを作成する:$/ do |table|
  table.hashes.each do |hash|
    unless User.find_by_uid hash[:owner]
      Given %!"#{hash[:owner]}"がユーザ登録する!
    end
    Given %!"#{hash[:owner]}"でログインする!
    Given %!"グループの新規作成ページ"にアクセスする!
    Given %!"#{"グループID"}"に"#{hash[:gid]}"と入力する!
    Given %!"#{"名称"}"に"#{hash[:name] ? hash[:name] : 'グループ'}"と入力する!
    Given %!"#{"説明"}"に"#{hash[:desc] ? hash[:desc] : '説明'}"と入力する!
    Given %!"#{"参加するのにオーナーの承認が必要ですか？"}"から"#{hash[:waiting] == 'true' ? 'はい' : 'いいえ'}"を選択する!
    Given %!"#{"作成"}"ボタンをクリックする!
  end
end

Given /^"([^\"]*)"が"([^\"]*)"グループに参加する$/ do |user, gid|
  Given %!"#{user}"でログインする!
  Given %!"#{gid}グループのトップページ"にアクセスする!
  Given %!"参加する"リンクをクリックする!
end
