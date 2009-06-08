# desc "Explaining what the task does"
# task :skip_embedded do
#   # Task goes here
# end
namespace :skip_embedded do
  require 'skip_embedded'

  desc "fetch clippy and jquery"
  task :thirdparty => %w[thirdparty:clippy thirdparty:jquery]

  namespace :thirdparty do
    require 'open-uri'

    desc "fetch clppy.swf from 'http://github.com/mojombo/clippy/raw/master/build/clippy.swf'"
    task :clippy do
      source = "http://github.com/mojombo/clippy/raw/master/build/clippy.swf"
      dest   = File.expand_path("public/flash", Rails.root)

      fetch(source, dest)
    end

    desc "fetch #{SkipEmbedded::Dependencies[:jquery]} from 'http://jqueryjs.googlecode.com/files/#{SkipEmbedded::Dependencies[:jquery]}'"
    task :jquery do
      source =  "http://jqueryjs.googlecode.com/files/#{SkipEmbedded::Dependencies[:jquery]}"
      dest   = File.expand_path("public/javascripts", Rails.root)

      fetch(source, dest)
    end
=begin
    desc "fetch jquery-ui-1.7.1.custom.zip from 'http://jqueryui.com/download/jquery-ui-1.7.1.custom.zip'"
    task :jqueryui do
      source =  'http://jqueryui.com/download/jquery-ui-1.7.1.custom.zip'
      dest   = File.expand_path("tmp/", Rails.root)

      fetch(source, dest)
    end
=end
    private
    def fetch(source, dest, filename_from_url = true)
      if File.directory?(dest) || filename_from_url
        dir, out = dest, File.basename(source)
      else
        dir, out = File.dirname(dest), File.basename(dest)
      end
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      Dir.chdir(dir){ File.open(out, "wb"){|f| f.write open(source).read } }
    end
  end
end
