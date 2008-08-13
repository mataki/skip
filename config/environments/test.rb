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

# 全文検索のHyperEstraierのノードマスタのURL
ESTRAIER_URL = 'http://localhost:1978/node/test1'

# シングルサインオン利用時のキーの値
SSO_KEY = 'hoge'

# 連携アプリがある場合の連携キー
SECRET_KEY = 'openskip'
# ----------------------------------------------------------------
