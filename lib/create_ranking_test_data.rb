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

(1..100).each do |i|
  title = SkipFaker.rand_char(4)
  url = "http://hoge.jp/#{title}"
  date = Date.today
  amount = 0
  (1..200).each do |j|
    date = date.ago(SkipFaker.rand_num(1).to_i.day)
    amount = amount + SkipFaker.rand_num(2).to_i
    create_ranking({ 
      :url => url,
      :title => title,
      :extracted_on => date,
      :amount => amount,
      :contents_type => 'comment_access'
    })
  end
end

