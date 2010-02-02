if SkipEmbedded::InitialSettings['exception_notifier']['enable']
  # exception_notifier
  ExceptionNotifier.exception_recipients = %(#{SkipEmbedded::InitialSettings['administrator_addr']})
  # defaults to exception.notifier@default.com
  ExceptionNotifier.sender_address = %(#{SkipEmbedded::InitialSettings['exception_notifier']['sender_addr']})
  # defaults to "[ERROR] "
  ExceptionNotifier.email_prefix = SkipEmbedded::InitialSettings['exception_notifier']['email_prefix'] || "[ERROR] "
end
