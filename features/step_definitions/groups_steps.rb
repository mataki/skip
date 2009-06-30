Given /^"([^\"]*)"で"([^\"]*)"というグループを作成する$/ do |user, gid|
  Given %!"#{user}"でログインする!
  visit url_for(:controller => 'groups', :action => 'new')
  Given   %!"#{"グループID"}"に"#{gid}"と入力する!
  Given   %!"#{"名称"}"に"テストグループ"と入力する!
  Given   %!"#{"説明"}"に"説明"と入力する!
  Given   %!"#{"作成"}"ボタンをクリックする!
end

When /^"([^\"]*)"で"([^\"]*)"グループのサマリページを開く$/ do |user, gid|
  Given %!"#{user}"でログインする!
  visit url_for(:controller => 'group', :gid => gid, :action => 'show')
end
