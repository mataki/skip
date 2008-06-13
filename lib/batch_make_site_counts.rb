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

class BatchMakeSiteCounts < BatchBase

  def self.execute options
    create_params = {}

    create_params[:total_user_count] = User.count(:conditions => ["retired = false"])
    create_params[:today_user_count] = UserAccess.count(:conditions => ["last_access > ?", Date.today])
    create_params[:total_blog_count] = BoardEntry.count
    create_params[:today_blog_count] = BoardEntry.count(:conditions => ["created_on > ?", Date.today])

    time_now = Time.now
    create_params[:writer_at_month] = self.calc_writer_at_month time_now
    create_params[:user_access_at_month] = self.calc_user_access_at_month time_now

    condition_sql = "SELECT count(distinct user_id) FROM board_entries where title not in ('参加申し込みをしました！','ユーザー登録しました！')"
    create_params[:write_users_with_bbs] = BoardEntry.count_by_sql(condition_sql)
    create_params[:write_users_with_pvt] = BoardEntry.count_by_sql(condition_sql += " and entry_type = 'DIARY'")
    create_params[:write_users_all] = BoardEntry.count_by_sql(condition_sql += " and publication_type = 'public'")

    create_params[:comment_users] = BoardEntryComment.count_by_sql("select count(distinct user_id) from board_entry_comments")
    create_params[:portrait_users] = Picture.count
    create_params[:profile_users] = UserProfile.count(:conditions => ["hometown <> 1 or address_1 <> 1"])
    create_params[:custom_users] = UserCustom.count
    create_params[:active_users] = UserAccess.count(:conditions => ["last_access >= ?", Date.today - 10]) # 10日以内にアクセスしたユーザをアクティブユーザとする

    SiteCount.delete_all ["created_on like ?", Date.today.strftime("%Y-%m-%d") + "%"]
    SiteCount.create(create_params)
  end

  # ここ一ヶ月以内にコメントかエントリを投稿したユーザー数
  # 自動投稿のエントリは除く（タイトルで除外している）
  def self.calc_writer_at_month time_now
    entries = BoardEntry.find(:all,
                              :select => "user_id, title",
                              :conditions => ["created_on BETWEEN ? and ?", time_now.last_month, time_now],
                              :order => "user_id")

    comments = BoardEntryComment.find(:all,
                                      :select => "distinct(user_id)",
                                      :conditions => ["created_on BETWEEN ? and ?", time_now.last_month, time_now])

    user_ids = []
    system_entry_titles = ['参加申し込みをしました！', 'ユーザー登録しました！']
    entries.each do |entry|
      user_ids << entry.user_id unless system_entry_titles.include?(entry.title)
    end
    user_ids |= comments.map{ |comment| comment.user_id }

    return user_ids.uniq.size
  end

private
  # ここ一ヶ月以内にログインしたユーザの平均カウント（平日のみ）
  def self.calc_user_access_at_month time_now
    # 今日以外のデータを取得
    site_counts = SiteCount.find(:all,
                                 :conditions => ["created_on BETWEEN ? and ?",
                                                 time_now.last_month, time_now.beginning_of_day])
    return calc_user_access_at_month_only_weekday(site_counts)
  end

  # SiteCountの配列から、土日祝日以外のアクセス数の平均を求める
  def  self.calc_user_access_at_month_only_weekday site_counts
    weekdays = [1,2,3,4,5] # 1:mon 2:tue... 5:fri
    total_user_access = 0
    cnt_user_access = 0

    site_counts.each do |site_count|
      if weekdays.include?(site_count.created_on.wday) and (not HOLIDAYS[site_count.created_on.to_date])
        total_user_access += site_count.today_user_count
        cnt_user_access += 1
      end
    end

    return (total_user_access.to_f / cnt_user_access.to_f)
  end

end

BatchMakeSiteCounts.execution
