module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

    when /the home\s?page/
      '/'

    when /マイページ/
      '/'

    when /管理ページ/
      '/admin/'

    when /グローバルのグループ一覧ページ/
      '/groups/'

    when /Wikiトップページ/
      wiki_path('トップページ')

    when /プロフィール画像一覧/
      admin_pictures_path

    when /^(.*)ユーザのプロフィールページ$/
      url_for(:controller => "/user", :action => "show", :uid => $1)

    when /全体からのブックマーク検索画面/
      url_for(:controller => '/bookmarks')

    when /ログインページ/
      "/platform"

    when /グループの新規作成ページ/
      url_for(:controller => 'groups', :action => 'new')

    when /(.*)ランキングの総合ページ/
      url_for(:controller => "rankings", :action => "data", :content_type => $1, :year => "", :month => "")

    when /^(.*)グループのトップページ$/
      url_for(:controller => "/group", :action => "show", :gid => $1)

    when /管理画面のユーザ一覧/
      admin_users_path


    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(User.find_by_login($1))

    else
      raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
        "Now, go and add a mapping in #{__FILE__}"
    end
  end
end

World(NavigationHelpers)
