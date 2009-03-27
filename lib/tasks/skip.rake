namespace :skip do
  desc "create release .zip archive."
  task :release do
    raise "This directory is not Git repository." unless File.directory?(".git")
    require 'zip/zip'
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
      system("zip #{out}.zip #{out}")
      system("tar zcvf #{out}.tar.gz #{out}")
      FileUtils.rm_rf out
    end
  end
end
