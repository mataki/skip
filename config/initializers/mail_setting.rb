# Mailer Setting from infro_setting
if ActiveRecord::Migrator.current_version > 20080811075535
  ActionMailer::Base.delivery_method = INITIAL_SETTINGS['delivery_method'].to_sym
  ActionMailer::Base.raise_delivery_errors = INITIAL_SETTINGS['raise_delivery_errors']
  ActionMailer::Base.smtp_settings = {
    :address => Admin::Setting.smtp_settings_address,
    :domain => Admin::Setting.smtp_settings_domain,
    :port => Admin::Setting.smtp_settings_port,
    :user_name => Admin::Setting.smtp_settings_user_name,
    :password => Admin::Setting.smtp_settings_password,
    :authentication => Admin::Setting.smtp_settings_authentication }
end
