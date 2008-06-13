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

# Tell ActionMailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

ENV['BATCH_ROOT_URL'] = "http://localhost"
ENV['BATCH_LOG_PATH'] = "#{RAILS_ROOT}/log/batch.log"

ENV['IMAGE_PATH'] = "tmp/test_image_files"
ENV['SHARE_FILE_PATH'] = "tmp/test_share_files"

DEVELOP_TEAM_GID = 'skipteam'
SECRET_KEY = 'openskip'

USER_CODE_FORMAT_REGEX = /^(\d{6}|[aA]\d{5})$/
ANTENNA_DEFAULT_GROUP = ["a_protected_group1"]

# ブックマーク情報取得用
ENV['PROXY_URL'] = 'http://192.168.50.193:8080/'

# マイページで表示するRSSフィードの設定
# デフォルトの1フィードあたりの最大表示件数
MYPAGE_FEED_DEFAULT_LIMIT = 3

# フィードの設定
# url:   フィードのURL
# title: フィードのタイトル(フィード内のタイトル以外のものを設定したい場合)
# limit: フィードの最大表示件数
MYPAGE_FEED_SETTINGS = [ { :url => "http://www.openskip.org/rss.xml", :title => "SKIPニュース" } ]

ActionController::AbstractRequest.relative_url_root = (ENV["RELATIVE_URL_ROOT"] || "")

ESTRAIER_URL = 'http://localhost:1978/node/test1'

SSO_KEY = 'hoge'
