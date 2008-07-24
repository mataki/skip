def create_ranking(options = {})
    ranking = Ranking.new({
      :url => 'http://user.openskip.org/',
      :title => 'SUG',
      :extracted_on => Date.today,
      :amount => 1,
      :contents_type => 'entry_access'}.merge(options))
    ranking.save
    ranking
end

if ARGV.empty?
  puts '第一引数でURLの数、第二引数で日数を指定して下さい。'
  puts '第二引数が省略された場合は10日分のデータを作成します。'
  exit -1
end

ARGV[1] = 10 unless ARGV[1]

start_time = Time.now
%w(entry_access entry_comment entry_he user_entry user_access).each do |contents_type|
  puts "#{contents_type}のデータを#{ARGV[0]}URL * #{ARGV[1]}日分作成します。"
  ActiveRecord::Base.transaction do
    (1..ARGV[0].to_i).each do |i|
      title = SkipFaker.rand_char(10)
      url = "http://hoge.jp/#{title}"
      author = SkipFaker.rand_char(4)
      author_url = "http://author.jp/#{author}"
      date = Date.today.ago(2.year)
      amount = 0
      (1..ARGV[1].to_i).each do |j|
        date = date.since(SkipFaker.rand_num(1).to_i.day)
        amount = amount + SkipFaker.rand_num(2).to_i
        create_ranking({ 
          :url => url,
          :title => title,
          :author => author,
          :author_url => author_url,
          :extracted_on => date,
          :amount => amount,
          :contents_type => contents_type
        })
      end
      puts "#{contents_type}のデータを作成中。(#{i*ARGV[1].to_i}/#{ARGV[0].to_i*ARGV[1].to_i} done #{(Time.now - start_time).to_s}) sec"
    end
  end
  puts "#{contents_type}のデータを作成しました。(#{(Time.now - start_time).to_s}) sec"
end
puts "done (#{(Time.now - start_time).to_s}) sec"
