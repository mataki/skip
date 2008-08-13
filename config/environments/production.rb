# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger        = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors if you bad email addresses should just be ignored
# config.action_mailer.raise_delivery_errors = false

#ActionController::AbstractRequest.relative_url_root = "/"

# ----設定項目----------------------------------------------------

# メールサーバ設定
ActionMailer::Base.delivery_method = :test
ActionMailer::Base.smtp_settings = { :address=> 'localhost', :port=> '25' }
ActionMailer::Base.raise_delivery_errors = false

# バッチ実行時のパラメータの設定
# バッチのログの出力先の設定
ENV['BATCH_LOG_PATH'] = "#{RAILS_ROOT}/log/batch.log"

# 画像や共有ファイルの保存先を設定
ENV['IMAGE_PATH'] = "#{RAILS_ROOT}/tmp/images"
ENV['SHARE_FILE_PATH'] = "#{RAILS_ROOT}/tmp/share_files"

# ブックマーク情報・RSS取得用プロキシ設定(なければnilとする)
ENV['PROXY_URL'] = nil
#ENV['PROXY_URL'] = 'http://localhost:8080/'

# 全文検索のHyperEstraierのノードマスタのURL
ESTRAIER_URL = 'http://localhost:1978/node/node1'

# シングルサインオン利用時のキーの値
SSO_KEY = 'skip'

# 連携アプリがある場合の連携キー
SECRET_KEY = 'skip'
# ----------------------------------------------------------------
