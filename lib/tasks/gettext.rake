desc "Create mo-files for L10n"
task :makemo do
  require 'gettext_rails/tools'
  GetText.create_mofiles
end

desc "Update pot/po files to match new version."
task :updatepo do
  require 'gettext_rails/tools'
  require 'locale_rails/i18n'
  ENV["MSGMERGE_PATH"] = "msgmerge --sort-output --no-fuzzy-matching"
  GetText.update_pofiles("skip", Dir.glob("{app}/**/*.{rb,erb}") + ["lib/symbol.rb"] + ['lib/skip_default_data.rb'] + ["config/environment.rb"] + ["lib/skip_util.rb"] + ["lib/create_new_admin_url.rb"], "skip 1.6.0")
end
