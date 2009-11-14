Given /^"(.*)"ユーザのプロフィールページに"(.*)"回アクセスする$/ do |user, num|
  num.to_i.times do
    Given %!"#{user}ユーザのプロフィールページ"にアクセスする!
  end
end

Given /^ランキングの"(.*)"位が"(.*)"のユーザであること$/ do |rank,uid|
  Nokogiri::HTML(response.body).search("table.ranking_square tbody tr:nth(#{rank}) td.column_title a.ranking_author").text.should == uid
end

Given /^"(.*)"回再読み込みする$/ do |num|
  num.to_i.times do |i|
    Given "再読み込みする"
  end
end

Given /^ランキングの"(.*)"位の数が"(.*)"であること$/ do |rank,num|
  Nokogiri::HTML(response.body).search("table.ranking_square tbody tr:nth(#{rank}) td.point").text.should == num.to_s
end

Given /^ランキングの"(.*)"位が"(.*)"つめのブログであること$/ do |rank,num|
  Nokogiri::HTML(response.body).search("table.ranking_square tbody tr:nth(#{rank}) td.column_title a.ranking_title").text.should == "test#{num}"
end

Given /^"(.*)"ランキングの"(.*)"分を表示する$/ do |category, date|
  year, month = date.split("-")
  visit ranking_data_path(:content_type => category, :year => year, :month => month)
end

Given /^ランキングのバッチで"(.*)"の"(.*)"分を実行する$/ do |method, date|
  @@bmr = BatchMakeRanking.new
  @@bmr.send(method.to_sym, Time.local(*date.split("-")))
end
# TODO: DRY
#       Time.localに変数を渡せない...
Given /^現在時刻の定義を一旦退避する$/ do
  class Time
    class << self
      alias origin_now now
    end
  end
end

Given /^現在時刻を2009-01-01とする$/ do
  class Time
    class << self
      def now
        Time.local(2009,1,1)
      end
    end
  end
end

Given /^現在時刻を2009-01-02とする$/ do
  class Time
    class << self
      alias origin_now now
      def now
        Time.local(2009,1,2)
      end
    end
  end
end

Given /^現在時刻を2009-02-01とする$/ do
  class Time
    class << self
      alias origin_now now
      def now
        Time.local(2009,2,1)
      end
    end
  end
end

Given /^現在時刻を2009-03-01とする$/ do
  class Time
    class << self
      alias origin_now now
      def now
        Time.local(2009,3,1)
      end
    end
  end
end

Given /^現在時刻を2009-03-02とする$/ do
  class Time
    class << self
      alias origin_now now
      def now
        Time.local(2009,3,2)
      end
    end
  end
end

Given /^現在時刻を元に戻す$/ do
  class Time
    class << self
      alias now origin_now
    end
  end
end
