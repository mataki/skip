namespace :skip do
  desc "Create release .zip archive."
  task :release do
    raise "This directory is not Git repository." unless File.directory?(".git")
    require 'fileutils'

    commit = ENV["COMMIT"] || "HEAD"
    if tag = ENV["TAG"]
      system(*["git", "tag", tag, commit])
      out = "skip-#{tag.gsub(/^v/, '')}"
      commit = tag
    else
      out = Time.now.strftime("skip-%Y%m%d%H%M%S")
    end
    FileUtils.mkdir_p "pkg/#{out}"
    system("git archive --format=tar #{commit} | tar xvf - -C pkg/#{out}")
    Dir.chdir("pkg/#{out}") do
      %w[log tmp].each{|d| Dir.mkdir d }
    end
    Dir.chdir("pkg") do
      system("zip -r #{out}.zip #{out}")
      system("tar zcvf #{out}.tar.gz #{out}")
      FileUtils.rm_rf out
    end
  end

  desc "Load default data."
  task :load_default_data => :environment do
    puts
    while true
      print "Select language: "
      print SkipDefaultData.valid_languages.join(',')
      print " [#{SkipDefaultData.default_language}] "
      STDOUT.flush
      lang = STDIN.gets.chomp!
      break if lang.empty?
      break if SkipDefaultData.valid_languages.include?(lang)
      puts "Unknown language!"
    end
    STDOUT.flush
    puts "===================================="

    begin
      SkipDefaultData.load(lang)
      puts "Default data loaded."
    rescue => error
      puts "Error: " + error
      puts "Default data was not loaded."
    end
  end

  namespace :collaboration_apps do
    desc "Synchronize the users of the given oauth provider"
    task :sync_users do
      require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")
      app_name = ENV['APP_NAME']
      ago = ENV['AGO']
      abort 'app_name was not specifed. ex) % rake skip:collaboration_apps:sync APP_NAME=\'wiki\' ' unless app_name
      abort 'collaboration_apps[\'app_name\'] was not specifed' unless SkipEmbedded::InitialSettings['collaboration_apps'][app_name]
      CollaborationApp::Oauth::UserSynchronizer.new(app_name).sync(ago)
    end

    desc "Synchronize the groups of the given oauth provider"
    task :sync_groups do
      require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")
      app_name = ENV['APP_NAME']
      ago = ENV['AGO']
      abort 'app_name was not specifed. ex) % rake skip:collaboration_apps:sync APP_NAME=\'wiki\' ' unless app_name
      abort 'collaboration_apps[\'app_name\'] was not specifed' unless SkipEmbedded::InitialSettings['collaboration_apps'][app_name]
      CollaborationApp::Oauth::GroupSynchronizer.new(app_name).sync(ago)
    end

    desc "Synchronize the users and groups of the given oauth provider"
    task :sync_all => [:sync_users, :sync_groups]
  end
end
