# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode
# (Use only when you can't set environment variables through your web/app server)
ENV['RAILS_ENV'] ||= 'production'

RAILS_GEM_VERSION = '2.1.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

require 'yaml'
INITIAL_SETTINGS = YAML.load(File.read(RAILS_ROOT + "/config/initial_settings.yml"))[RAILS_ENV]

Rails::Initializer.run do |config|
  config.action_controller.session = INITIAL_SETTINGS['session']
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
  # config.gem "gettext"
  # config.gem "uuidtools"
  # config.gem "fastercsv"
  # config.gem "ruby-openid", :lib => "openid"
  # config.gem "mongrel"
  # config.gem "rspec", :lib => "spec"
  # config.gem "rspec-rails"
  # config.gem "ZenTest", :lib => "zentest"
  # config.gem "ruby-debug"
end

# Include your application configuration below
ENV['IMAGE_PATH'] ||= INITIAL_SETTINGS['image_path']
ENV['SHARE_FILE_PATH'] ||= INITIAL_SETTINGS['share_file_path']
ENV['BATCH_LOG_PATH'] ||= INITIAL_SETTINGS['batch_log_path'] || "#{RAILS_ROOT}/log/batch.log"
ENV['SECRET_KEY'] ||= INITIAL_SETTINGS['secret_key']

menu_btns = [
             { :img_name => "house",
               :id => "btn_mypage",
               :name => "マイページ",
               :url => {:controller => '/mypage', :action => 'index'},
               :desc => "自分用のトップページに戻ります"},

             { :img_name => "report",
               :id => "btn_entries",
               :name => "記事",
               :url => {:controller => '/search', :action => 'entry_search' },
               :desc => "ブログや掲示板の記事を探します"},

             { :img_name => "disk_multiple",
               :id => "btn_share_files",
               :name => "ファイル",
               :url => {:controller => '/search', :action => 'share_file_search' },
               :desc => "ユーザやグループで共有しているファイルを探します"},

             { :img_name => "user_suit",
               :id => "btn_users",
               :name => "ユーザ",
               :url => {:controller => '/users', :action => 'index'},
               :desc => "利用中のユーザや紹介文を探します"},

             { :img_name => "group",
               :id => "btn_groups",
               :name => "グループ",
               :url => {:controller => '/groups', :action => 'index'},
               :desc => "他のユーザが作ったグループを探します"},

             { :img_name => "tag_blue",
               :id => "btn_bookmarks",
               :name => "ブックマーク",
               :url => {:controller => '/bookmarks', :action => 'index'},
               :desc => "共有しているブックマーク（URL）を探します"},

             { :img_name => "chart_bar",
               :id => "btn_rankings",
               :name => "ランキング",
               :url => {:controller => '/rankings', :action => 'index'},
               :desc => "ランキング情報と統計情報を見ます"}
]
menu_btns << { :img_name => "page_find",
               :id => "btn_search",
               :name => "全文検索",
               :url => {:controller => '/search', :action => 'full_text_search' },
               :desc => "キーワードでサイト全体から検索します" } if INITIAL_SETTINGS['full_text_search_setting']
MENU_BTNS = menu_btns

admin_btns = [
              {:img_name => "database_gear",
               :id => "btn_admin",
               :name => "設定・管理",
               :url => {:controller => '/admin', :action => 'index'},
               :desc => "このシステムの設定や管理を行います" },
]
ADMIN_MENU_BTNS = admin_btns

# 共通メニュー
COMMON_MENUS = YAML::load(File.open(File.join(RAILS_ROOT, 'config', 'common_menus.yml')))
COMMON_MENUS[:main_menus] = [] unless COMMON_MENUS[:main_menus]
COMMON_MENUS[:block_menus] = [] unless COMMON_MENUS[:block_menus]

# 祝日マスタ
HOLIDAYS = YAML::load(File.open(File.join(RAILS_ROOT, 'config', 'holiday.yml')))

require File.join(File.dirname(__FILE__), '..', 'lib', 'hikidoc')
require 'skip_util'
require 'web_service_util'
