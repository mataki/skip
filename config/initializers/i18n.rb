I18n.supported_locales = Dir[ File.join(RAILS_ROOT, 'lib', 'locale', '*.{rb,yml}') ].collect{|v| File.basename(v, ".*")}.uniq
I18n.default_locale = SkipEmbedded::InitialSettings['default_locale']
