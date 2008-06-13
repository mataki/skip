# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

#ActionController::AbstractRequest.relative_url_root = (ENV["RELATIVE_URL_ROOT"] || "")

# ----設定項目----------------------------------------------------

# メールサーバ設定
# Tell ActionMailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

# バッチ実行時のパラメータの設定
# バッチのログの出力先の設定
ENV['BATCH_LOG_PATH'] = "#{RAILS_ROOT}/log/batch.log"

# 画像や共有ファイルの保存先を設定
ENV['IMAGE_PATH'] = "tmp/test_image_files"
ENV['SHARE_FILE_PATH'] = "tmp/test_share_files"

# ブックマーク情報取得用
ENV['PROXY_URL'] = nil

# ニックネームとして許可しない形式を指定
# 登録時に管理番号(社員番号)などと重複しないように
USER_CODE_FORMAT_REGEX = /^(\d{6}|[aA]\d{5})$/

# 要望・不具合受付グループのID
DEVELOP_TEAM_GID = 'skipteam'

# 初期のアンテナに追加されるグループを指定する(なければ空配列とする)
ANTENNA_DEFAULT_GROUP = ["a_protected_group1"]

# マイページで表示するRSSフィードの設定
# デフォルトの1フィードあたりの最大表示件数
MYPAGE_FEED_DEFAULT_LIMIT = 3

# フィードの設定
# url:   フィードのURL
# title: フィードのタイトル(フィード内のタイトル以外のものを設定したい場合)
# limit: フィードの最大表示件数
# ex) RSSを表示しない場合、以下のように設定する
# MYPAGE_FEED_SETTINGS = []
# ex) 複数のRSSを表示する場合　上から表示する順に以下のように並べる
# MYPAGE_FEED_SETTINGS = [ { :url => "http://www.openskip.org/rss.xml", :title => "SKIPニュース" },
#                          { :url => "http://example.com/rss" } ]
MYPAGE_FEED_SETTINGS = [ { :url => "http://www.openskip.org/rss.xml", :title => "SKIPニュース" } ]

# 全文検索のHyperEstraierのノードマスタのURL
ESTRAIER_URL = 'http://localhost:1978/node/test1'

# シングルサインオン利用時のキーの値
SSO_KEY = 'hoge'

# 連携アプリがある場合の連携キー
SECRET_KEY = 'openskip'
# ----------------------------------------------------------------
