# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes     = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils        = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false
config.action_view.debug_rjs                         = true

#ActionController::AbstractRequest.relative_url_root = (ENV["RELATIVE_URL_ROOT"] || "")

# ----設定項目----------------------------------------------------

# メールサーバ設定 # Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false
config.action_mailer.delivery_method = :test

# バッチ実行時のパラメータの設定
# バッチのログの出力先の設定
ENV['BATCH_LOG_PATH'] ||= "#{RAILS_ROOT}/log/batch.log"

# 画像や共有ファイルの保存先を設定
ENV['IMAGE_PATH'] ||= "temp_image_file_path"
ENV['SHARE_FILE_PATH'] ||= "temp_share_file_path"

# ブックマーク情報取得用
ENV['PROXY_URL'] ||= nil

# 全文検索のHyperEstraierのノードマスタのURL
ESTRAIER_URL = 'http://localhost:1978/node/node1'

# シングルサインオン利用時のキーの値
SSO_KEY = 'hoge'

# 連携アプリがある場合の連携キー
SECRET_KEY = 'openskip'
# ----------------------------------------------------------------
