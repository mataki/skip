ActionMailer::Base.delivery_method = INITIAL_SETTINGS['delivery_method'].to_sym
ActionMailer::Base.raise_delivery_errors = INITIAL_SETTINGS['raise_delivery_errors']

# DBの設定(設定されていなければSetting.yml)を読み出してSMTPの接続パラメータとする
# ExceptionNotifierプラグインを利用しているためActionMailerを上書きした
module ActionMailer
  class Base
    private
    def smtp_settings
      { :address => Admin::Setting.smtp_settings_address,
        :port => Admin::Setting.smtp_settings_port,
        :domain => Admin::Setting.smtp_settings_domain,
        :user_name => Admin::Setting.smtp_settings_user_name,
        :password => Admin::Setting.smtp_settings_password,
      :authentication => Admin::Setting.smtp_settings_authentication }
    end
  end
end
