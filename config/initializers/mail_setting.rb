# Mailer Setting from infro_setting
ActionMailer::Base.delivery_method = Setting.delivery_method.to_sym
ActionMailer::Base.raise_delivery_errors = Setting.raise_delivery_errors
ActionMailer::Base.smtp_settings = {
  :address => Setting.smtp_settings[:address],
  :domain => Setting.smtp_settings[:domain],
  :port => Setting.smtp_settings[:port],
  :user_name => Setting.smtp_settings[:user_name],
  :password => Setting.smtp_settings[:password],
  :authentication => Setting.smtp_settings[:authentication] }
