# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes     = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils        = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false
config.action_view.cache_template_extensions         = false
config.action_view.debug_rjs                         = true

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false
config.action_mailer.delivery_method = :test

ENV['BATCH_LOG_PATH'] ||= "#{RAILS_ROOT}/log/batch.log"

ENV['IMAGE_PATH'] ||= "temp_image_file_path"
ENV['SHARE_FILE_PATH'] ||= "temp_share_file_path"

DEVELOP_TEAM_GID = 'skipteam'
SECRET_KEY = 'openskip'

USER_CODE_FORMAT_REGEX = /^(\d{6}|[kK]\d{5})$/
ANTENNA_DEFAULT_GROUP = ["tcpdevelop", "magazine"]

# ブックマーク情報取得用
ENV['PROXY_URL'] ||= 'http://192.168.50.193:8080/'

# マイページで表示するRSSフィードの設定
# デフォルトの1フィードあたりの最大表示件数
MYPAGE_FEED_DEFAULT_LIMIT = 3

# フィードの設定
# url:   フィードのURL
# title: フィードのタイトル(フィード内のタイトル以外のものを設定したい場合)
# limit: フィードの最大表示件数
MYPAGE_FEED_SETTINGS = [ { :url => "http://www.openskip.org/rss.xml", :title => "SKIPニュース" } ]

ActionController::AbstractRequest.relative_url_root = (ENV["RELATIVE_URL_ROOT"] || "")

ESTRAIER_URL = 'http://localhost:1978/node/node1'

SSO_KEY = 'hoge'
