ActionMailer::Base.raise_delivery_errors = SkipEmbedded::InitialSettings['raise_delivery_errors']

ActionMailer::Base.smtp_settings = SkipEmbedded::InitialSettings['exception_notifier']['smtp_settings']
