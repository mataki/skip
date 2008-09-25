# SKIP（Social Knowledge & Innovation Platform）
# Copyright (C) 2008  TIS Inc.
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

# 1日分のランキング元データを生成
# 送信するデータは、送信日時点でのこれまでの累積値(!=前日からの差分)
# 表示時には、本バッチで生成したデータを集計するのみ。
class BatchMakeRanking < BatchBase

  def self.execute options

    unless @@target_day = options[:exec_day]
      @@target_day = Date.today -1
    end 

    begin
      ActiveRecord::Base.transaction do
        # バッチのリラン用
        Ranking.destroy_all(['extracted_on = ?', @@target_day])

        # アクセス数
        BoardEntryPoint.find(:all, :conditions => make_conditions("access_count > 0")).each do |entrypoint|
          entry = entrypoint.board_entry
          if published? entry
            create_ranking_by_entry entry, entrypoint.access_count, "entry_access"
          end
        end

        # コメント数
        BoardEntry.find(:all, :conditions => make_conditions("board_entry_comments_count > 0")).each do |entry|
          if published? entry
            create_ranking_by_entry entry, entry.board_entry_comments_count, "entry_comment"
          end
        end

        # へー
        BoardEntryPoint.find(:all, :conditions => make_conditions("point > 0")).each do |entrypoint|
          entry = entrypoint.board_entry 
          if published? entry
            create_ranking_by_entry entry, entrypoint.point, "entry_he"
          end
        end

        # 訪問者数
        UserAccess.find(:all, :conditions => make_conditions("access_count > 0")).each do |access|
          user = access.user
          create_ranking_by_user user, access.access_count, "user_access"
        end

        # 投稿数
        BoardEntry.find(:all, :conditions => make_conditions("entry_type = 'DIARY'"), 
                        :select => "user_id, MAX(user_entry_no) as user_entry_no", 
                        :group => "user_id").each do |record|
          user = User.find(record.user_id) 
          create_ranking_by_user user, record.user_entry_no, "user_entry" 
        end

        # コメンテータ
        # skip上に累積値を持たないため、導出
        sql = <<-SQL
              SELECT user_id,COUNT(*) AS comment_count
              FROM board_entry_comments
              WHERE user_id IN (
                SELECT distinct user_id
                FROM board_entry_comments
                WHERE DATE_FORMAT(updated_on,'%Y%m%d') = :commentator_conditions
              )
              AND DATE_FORMAT(updated_on,'%Y%m%d') <= :commentator_conditions
              GROUP BY user_id
              SQL
        BoardEntryComment.find_by_sql([sql, { :commentator_conditions => @@target_day.strftime('%Y%m%d') }]).each do |record|
          user = User.find(record.user_id)
          create_ranking_by_user user, record.comment_count, "commentator"
        end
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      e.backtrace.each { |line| log_error line}
    end
  end

private
  def self.make_conditions condition
    [condition + " AND DATE_FORMAT(updated_on,'%Y%m%d') = ? ", @@target_day.strftime('%Y%m%d')]
  end

  def self.published? entry
    entry.entry_publications.any?{|publication| publication.symbol == Symbol::SYSTEM_ALL_USER }
  end

  def self.create_ranking url, title, author, author_url, amount, contents_type
    ranking = Ranking.new(
      :url => url,
      :title => title,
      :author => author,
      :author_url => author_url,
      :extracted_on => @@target_day,
      :amount => amount,
      :contents_type => contents_type
    )
    ranking.save!
  end

  def self.create_ranking_by_entry entry, amount, contents_type
    create_ranking page_url(entry.id), entry.title, entry.user.name, 
      user_url(entry.user.uid), amount, contents_type
  end

  def self.create_ranking_by_user user, amount, contents_type
    create_ranking user_url(user.uid), user.name, user.name,
      user_url(user.uid), amount, contents_type
  end

  def self.user_url str
   ENV['SKIP_URL'] + "/user/" + str.to_s 
  end

  def self.page_url str
   ENV['SKIP_URL'] + "/page/" + str.to_s
  end
end


# 引数は、シェルからの実行用。集計対象日を'YYYYMMDD'形式で渡せる。
# cronからの日次実行時には、引数は不要。

def convert_date str
  Date.new(str[0,4].to_i, str[4,2].to_i, str[6,2].to_i)
end

from_day = ARGV[0] || Time.now.strftime('%Y%m%d') 
to_day   = ARGV[1]

unless to_day 
  BatchMakeRanking.execution({:exec_day => convert_date(from_day)}) 
else
  (convert_date(from_day)..convert_date(to_day)).each do |exec_date|
    BatchMakeRanking.execution({ :exec_day => exec_date}) 
  end 
end

