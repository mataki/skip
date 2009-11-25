Given /^ブックマークレットのページをURL"(.*)"で表示する$/ do |url|
  visit url_for(:controller => "bookmark", :action => "new", :url => url)
end

Given /^ブックマークの詳細ページをURL"(.*)"で表示する$/ do |url|
  visit url_for(:controller => "bookmark", :action => "show", :url => url)
end

Given /^URLが"(.*)"で文字列が"(.*)"のリンクが存在すること$/ do |url, title|
  Nokogiri::HTML(response.body).search("a[href=\"#{url}\"]").select{|a| a.text.include?(title) }.should_not be_empty
end

Given /^URLが"(.*)"タイトルが"(.*)"コメントが"(.*)"のブックマークを登録する$/ do |url, title, comment|
  Given  "ブックマークレットのページをURL\"#{url}\"で表示する"
  Given    "\"タイトル\"に\"#{title}\"と入力する"
  Given    "\"コメント\"に\"#{comment}\"と入力する"
  Given    "\"保存\"ボタンをクリックする"
end

Given /^以下のブックマークのリストを登録している:$/ do |bookmarks_table|
  bookmarks_table.hashes.each do |hash|
    uid = hash[:user] || 'a_user'
    Given %!"#{uid}"がユーザ登録する!  unless User.find_by_uid(uid)
    Given %!"#{uid}"でログインする!
    Given %!URLが"#{hash[:url]}"タイトルが"#{hash[:title]}"コメントが"#{hash[:comment]}"のブックマークを登録する!
  end
end
