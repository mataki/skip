# Mailer Setting from infro_setting
ActionMailer::Base.delivery_method = Admin::Setting.delivery_method.to_sym
ActionMailer::Base.raise_delivery_errors = Admin::Setting.raise_delivery_errors
ActionMailer::Base.smtp_settings = {
  :address => Admin::Setting.smtp_settings[:address],
  :domain => Admin::Setting.smtp_settings[:domain],
  :port => Admin::Setting.smtp_settings[:port],
  :user_name => Admin::Setting.smtp_settings[:user_name],
  :password => Admin::Setting.smtp_settings[:password],
  :authentication => Admin::Setting.smtp_settings[:authentication] }
