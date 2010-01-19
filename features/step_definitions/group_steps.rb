Given /^"([^\"]*)"で"([^\"]*)"というグループを作成する$/ do |user, gid|
  unless Group.find_by_gid(gid)
    Given %!"#{user}"でログインする!
    Given %!"グループの新規作成ページ"にアクセスする!
    Given %!"#{"グループID"}"に"#{gid}"と入力する!
    Given %!"#{"名称"}"に"テストグループ"と入力する!
    Given %!"#{"説明"}"に"説明"と入力する!
    Given %!"#{"作成"}"ボタンをクリックする!
  end
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

Given /^"([^\"]*)"が"([^\"]*)"グループを退会する$/ do |user, gid|
  Given %!"#{user}"でログインする!
  Given %!"#{gid}グループのトップページ"にアクセスする!
  Given %!"退会する"リンクをクリックする!
end

# TODO 無理やりすぎる。change_participationをリファクタしてからここも書き直す
Given /^"([^\"]*)"で"([^\"]*)"の"([^\"]*)"グループへの参加を承認する$/ do |admin_uid, target_uid, gid|
  Given %!"#{admin_uid}"でログインする!
  group = Group.find_by_gid(gid)
  user = User.find_by_uid(target_uid)
  gp = group.group_participations.find_by_user_id(user.id)
  visit( url_for({
      :controller => 'group',
      :gid => gid,
      :action => 'change_participation',
      :participation_state => {gp.id.to_s => true},
      :submit_type => 'permit'
  }), :post)
end

Given /^"([^\"]*)"で"([^\"]*)"の"([^\"]*)"グループへの参加を棄却する$/ do |admin_uid, target_uid, gid|
  Given %!"#{admin_uid}"でログインする!
  group = Group.find_by_gid(gid)
  user = User.find_by_uid(target_uid)
  gp = group.group_participations.find_by_user_id(user.id)
  visit( url_for({
      :controller => 'group',
      :gid => gid,
      :action => 'change_participation',
      :participation_state => {gp.id.to_s => true},
      :submit_type => 'reject'
  }), :post)
end

Given /^"([^\"]*)"で"([^\"]*)"を"([^\"]*)"グループへ強制参加させる$/ do |admin_uid, target_uid, gid|
  Given %!"#{admin_uid}"でログインする!
  Given %!"#{gid}グループのトップページ"にアクセスする!
  Given %!"管理"リンクをクリックする!
  Given %!"参加者管理"リンクをクリックする!
  Given %!"symbol"に"uid:#{target_uid}"と入力する!
  Given %!"参加者に追加"ボタンをクリックする!
end

Given /^"([^\"]*)"で"([^\"]*)"を"([^\"]*)"グループから強制退会させる$/ do |admin_uid, target_uid, gid|
  Given %!"#{admin_uid}"でログインする!
  Given %!"#{gid}グループのトップページ"にアクセスする!
  Given %!"管理"リンクをクリックする!
  Given %!"参加者管理"リンクをクリックする!
  # FIXME どのリンクを押すのか指定出来るように対象のhtmlを見直してから修正する
  Given %!"[強制退会させる]"リンクをクリックする!
end
