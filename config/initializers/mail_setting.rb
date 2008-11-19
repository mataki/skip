ActionMailer::Base.raise_delivery_errors = INITIAL_SETTINGS['raise_delivery_errors']

ActionMailer::Base.delivery_method = INITIAL_SETTINGS['exception_notifier']['enable'] ? :smtp : :test
ActionMailer::Base.smtp_settings = INITIAL_SETTINGS['exception_notifier']['smtp_settings']
