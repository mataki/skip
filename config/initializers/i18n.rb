I18n.supported_locales = Dir[File.join(RAILS_ROOT, "locale/*")].collect{|v| File.basename(v)}
I18n.default_locale = SkipEmbedded::InitialSettings['default_locale']
