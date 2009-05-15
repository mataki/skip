Given /^"(.*)"で"(.*)"つめのブログにアクセスする$/ do |user, num|
  Given %!"#{user}"でログインする!
  entry = @entries[num.to_i - 1]
  visit url_for(:controller => "user", :entry_id => entry[:id], :action => "blog", :uid => entry[:uid])
end

Given /^"(.*)"でブログを書く$/ do |user|
  @entries ||= []
  Given %!"#{user}"でログインする!
  Given %!"ブログを書く"リンクをクリックする!
  Given %!"#{"board_entry[title]"}"に"#{"test"+(@entries.size+1).to_s}"と入力する!
  Given %!"#{"editor_mode_hiki"}"を選択する!
  Given %!"#{"contents_hiki"}"に"#{"test"}"と入力する!
  Given %!"#{"作成"}"ボタンをクリックする!
  entry = BoardEntry.last
  @entries << { :id => entry.id, :uid => entry.symbol.split(":").last }
end

Given /^"(.*)"でブログを"(.*)"回書く$/ do |user, num|
  num.to_i.times do
    Given "ログアウトする"
    Given %!"#{user}"でブログを書く!
  end
end

Given /^"(.*)"で"(.*)"つめのブログにポイントを"(.*)"回つける$/ do |user,target,num|
  Given %!"#{user}"でログインする!
  entry = @entries[target.to_i - 1]
  num.to_i.times do
    visit(url_for(:controller => :board_entries, :action => :ado_pointup, :id => entry[:id]), :post)
  end
end

Given /^"(.*)"でコメントを"(.*)"回書く$/ do |user, times|
  Given "ログアウトする"
  Given %!"#{user}"でログインする!
  Given %!"1"つめのブログに"#{times}"回コメントを書く!
end

Given /^"(.*)"つめのブログに"(.*)"回コメントを書く$/ do |num,times_num|
  entry = @entries[num.to_i - 1]
  (1..times_num.to_i).each do
    visit(url_for(:controller => :board_entries, :action => :ado_create_comment,:id => entry[:id], :board_entry_comment => { :contents => "test" }), :post)
  end
end
