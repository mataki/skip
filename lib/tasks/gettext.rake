require 'gettext/utils'

desc "Create mo-files for L10n"
task :makemo do
  GetText.create_mofiles(true, "po", "locale")
end

desc "Update pot/po files to match new version."
task :updatepo do
  ENV["MSGMERGE_PATH"] = "msgmerge --sort-output"
  GetText.update_pofiles("skip", Dir.glob(["{app}/**/*.{rb,erb}","lib/admin_module.rb"]) - ["app/models/user_mailer.rb"], "skip 0.1.0")
end
