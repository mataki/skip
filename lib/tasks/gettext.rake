desc "Create mo-files for L10n"
task :makemo do
  require 'gettext/utils'
  GetText.create_mofiles(true, "po", "locale")
end

desc "Update pot/po files to match new version."
task :updatepo do
  require 'gettext/utils'
  ENV["MSGMERGE_PATH"] = "msgmerge --sort-output"
  GetText.update_pofiles("skip", Dir.glob("{app}/**/*.{rb,erb}") + ["lib/symbol.rb"] - ["app/models/user_mailer.rb"], "skip 0.1.0")
end
