Given /^以下の紹介文を作成する:$/ do |table|
  table.hashes.each do |hash|
    unless User.find_by_uid hash[:from_user]
      Given %!"#{hash[:from_user]}"がユーザ登録する!
    end
    unless User.find_by_uid hash[:to_user]
      Given %!"#{hash[:to_user]}"がユーザ登録する!
    end
    Given %!"#{hash[:from_user]}"でログインする!
    Given %!"#{hash[:to_user]}ユーザのプロフィールページ"にアクセスする!
    Given %!"みんなに紹介する"リンクをクリックする!
    Given %!"chain_comment"に"#{hash[:comment]}"と入力する!
    Given %!"作成"ボタンをクリックする!
  end
end
