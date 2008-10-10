ENABLE_EXCEPTION_NOTIFIER = false
# exception_notifier
ExceptionNotifier.exception_recipients = %w(skip@example.com)
# defaults to exception.notifier@default.com
ExceptionNotifier.sender_address = %("Application Error" <app.error@example.com>)
# defaults to "[ERROR] "
ExceptionNotifier.email_prefix = "[ERROR] "
