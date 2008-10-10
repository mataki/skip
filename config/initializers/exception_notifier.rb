if INITIAL_SETTINGS['exception_notifier']['enable']
  # exception_notifier
  ExceptionNotifier.exception_recipients = %(#{INITIAL_SETTINGS['administrator_addr']})
  # defaults to exception.notifier@default.com
  ExceptionNotifier.sender_address = %(#{INITIAL_SETTINGS['exception_notifier']['sender_addr']})
  # defaults to "[ERROR] "
  ExceptionNotifier.email_prefix = "[ERROR] "
end
