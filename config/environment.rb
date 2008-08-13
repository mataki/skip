# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode
# (Use only when you can't set environment variables through your web/app server)
ENV['RAILS_ENV'] ||= 'production'

RAILS_GEM_VERSION = '2.1.0' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.action_controller.session = {
    :session_key => '_skip_session',
    :secret      => '0b77a6ad8bcfb834e34f161f0cbba9877929e0cb03f4ffeda64b84aa47f66f68032d77bc642ad497661296c015342c2d93ac21b097da7f7491e18f749bde75a7'
  }
  # config.action_controller.session_store = :p_store

  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake create_sessions_table')
  # config.action_controller.session_store = :active_record_store

  # Enable page/fragment caching by setting a file-based store
  # (remember to create the caching directory and make it readable to the application)
  # config.action_controller.fragment_cache_store = :file_store, "#{RAILS_ROOT}/cache"

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc

  # Use Active Record's schema dumper instead of SQL when creating the test database
  # (enables use of different database adapters for development and test environments)
  # config.active_record.schema_format = :ruby

  # See Rails::Configuration for more options
end

# Include your application configuration below

# ----設定項目----------------------------------------------------
# accountテーブルのパスワードSHA1暗号化用キー
SHA1_DIGEST_KEY = 'change-me'

# 全文検索の所属情報を持つアプリの設定
BELONG_INFO_APPS = {}
#BELONG_INFO_APPS = { :app_name => { :api => :api_name, :hash_key => 'hash_key_name', :prefix => 'prefix' } }

# SIKPoPモードを有効にする
ENV['SKIPOP_URL'] ||= nil
# ----------------------------------------------------------------

menu_btns = [
  { :img_name => "house",         :id => "btn_mypage", :name => "マイページ", :url => {:controller => '/mypage', :action => 'index'} },

  { :separator => true, :name => "[マイメニュー]"},

  { :img_name => "vcard",         :id => "btn_profile", :name => "プロフィール", :url => {:controller => '/mypage', :action => 'profile'} },
  { :img_name => "report",        :id => "btn_my_blog", :name => "マイブログ", :url => {:controller => '/mypage', :action => 'blog'} },
  { :img_name => "book_open",     :id => "btn_my_bookmark", :name => "マイブクマ", :url => {:controller => '/mypage', :action => 'bookmark'} },
  { :img_name => "disk_multiple", :id => "btn_manage", :name => "マイファイル", :url => {:controller => '/mypage', :action => 'share_file'} },
  { :img_name => "cog",           :id => "btn_manage", :name => "自分の管理", :url => {:controller => '/mypage', :action => 'manage'} },

  { :separator => true, :name => "[全体メニュー]"},

  { :img_name => "user_suit",     :id => "btn_users", :name => "ユーザ", :url => {:controller => '/users', :action => 'index'} },
  { :img_name => "group",         :id => "btn_groups", :name => "グループ", :url => {:controller => '/groups', :action => 'index'} },
  { :img_name => "book",          :id => "btn_bookmarks", :name => "ブックマーク", :url => {:controller => '/bookmarks', :action => 'index'} },
  { :img_name => "chart_bar",     :id => "btn_rankings", :name => "ランキング", :url => {:controller => '/rankings', :action => 'index'} },
  { :img_name => "bricks",        :id => "btn_develop", :name => "サイト情報", :url => {:controller => '/develop', :action => 'index'} },

  { :separator => true, :name => "[アクション]"},

  { :img_name => "page_find",     :id => "btn_search", :name => "データを探す", :url => {:controller => '/search', :action => 'index'} },
  { :img_name => "report_edit",   :id => "btn_edit", :name => "ブログを書く", :url => {:controller => '/edit', :action => 'index'} },
]
MENU_BTNS = menu_btns

# 全文検索の検索条件設定
SEARCHAPPS = YAML::load(File.open(File.join(RAILS_ROOT, 'config', 'searchapps.yml')))[RAILS_ENV]
ORDERED_SEARCHAPPS = SEARCHAPPS.sort_by{|key, value| value["order"]}.unshift(['all' , {'title' => '全体'}])

# 祝日マスタ
HOLIDAYS = YAML::load(File.open(File.join(RAILS_ROOT, 'config', 'holiday.yml')))
