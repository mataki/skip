namespace :skip do

  desc "[SKIP-Original]Load csvdatas into the current environment's database"
  task :load_csvdatas => :environment do
    require 'active_record/fixtures'
    raise "TARGET_SCHEMA を指定してください" unless ENV['TARGET_SCHEMA']

    ActiveRecord::Base.establish_connection(ENV['TARGET_SCHEMA'])
    Dir.glob(File.join(RAILS_ROOT, 'db', '*.{yml,csv}')).each do |fixture_file|
      Fixtures.create_fixtures('db', File.basename(fixture_file, '.*'))
    end
  end

  desc "[SKIP-Original]Create csv files at db."
  task :save_csvdatas => :environment do
    require File.join(RAILS_ROOT, 'lib', 'tasks', 'tasks_environment')
    raise "TARGET_SCHEMA を指定してください" unless ENV['TARGET_SCHEMA']

    ActiveRecord::Base.establish_connection(ENV['TARGET_SCHEMA'])
    connection = ActiveRecord::Base.connection
    connection.tables.sort.each do |table|
      next if table == "schema_info"
      next if EXCLUSION_TALBE_SAVE_CSVDATAS.include?(table)
      File.open((ENV['OUTPUT'] || "db") + "/#{table}.csv", "w") do |file|

        columns = connection.columns(table)
        columns.each do |column|
          file.print column.name
          file.print ", " unless columns.last == column
        end
        file.puts

        sql = "SELECT * FROM #{table}"
        connection.select_all(sql).each do |row|
          columns.each do |column|
            print_str = row[column.name]
            print_str = print_str.gsub('"', '""').gsub('<%','< %') if print_str
            file.print '"'
            file.print print_str
            file.print '"'
            file.print "," unless columns.last == column
          end
          file.puts
        end
      end
    end
  end

  desc "[SKIP-Original]Continuous Integration"
  task :test => :environment do
    svn_result =  `svn up`
    migrate_result =  `rake migrate RAILS_ENV=test`

    test_log = `rake`
    test_count = assert_count = fail_count = error_count = 0
    test_log.scan(/[0-9]*\stests,\s[0-9]*\sassertions,\s[0-9]*\sfailures,\s[0-9]*\serrors/).each do |test_result|
      test_count   += test_result.to_s.match(/[0-9]*\stests/).to_s.split(" ").first.to_i
      assert_count += test_result.to_s.match(/[0-9]*\sassertions/).to_s.split(" ").first.to_i
      fail_count   += test_result.to_s.match(/[0-9]*\sfailures/).to_s.split(" ").first.to_i
      error_count  += test_result.to_s.match(/[0-9]*\serrors/).to_s.split(" ").first.to_i
    end

    result_color = (fail_count + error_count) > 0 ? "red" : "green"

    dir_path  = "continuous_test_log/"
    file_name = Time.now.strftime("%Y%m%d_%H%M_test_#{result_color}.log")
    File.open(dir_path + file_name, "w"){|file|
      file.puts "[svn up]"
      file.puts svn_result
      file.puts "------------------------------------------------------------"
      file.puts "[rake migrate]"
      file.puts migrate_result
      file.puts "------------------------------------------------------------"
      file.puts test_log
    }

    result_html = `erb lib/tasks/continuous.erb`
    File.open("public/continuous.html", "w"){ |file|
      file.puts result_html
    }
  end

  desc "[SKIP-Original]Data Masking"
  task :masking => :environment do
    raise "TARGET_SCHEMA を指定してください" unless ENV['TARGET_SCHEMA']
    ActiveRecord::Base.establish_connection(ENV['TARGET_SCHEMA'])
    p "execute masking to <#{ENV['TARGET_SCHEMA']}>schema?[y/n]"
    res = STDIN.gets
    if res == "y\n"
      DataMasking.execute
      p "masking done..."
    end
  end

  desc "[SKIP-Original]Load csvdatas into the TARGET_SCHEMA and masking"
  task :load_csvdatas_for_test => :environment do
    Rake::Task[:load_csvdatas].invoke
    Rake::Task['skip:masking'].invoke
  end

  # alias
  desc "[SKIP-Original]Load csvdatas into the TARGET_SCHEMA"
  # todo

  desc "[SKIP-Original]Create csv files at db."
  # todo

end
