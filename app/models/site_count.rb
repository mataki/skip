# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2010 TIS Inc.
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

class SiteCount < ActiveRecord::Base
  STATISTICS_KEYS = %w(total_user_count today_user_count total_blog_count today_blog_count writer_at_month user_access_at_month).freeze
  STATISTICS_ITEMS = {
    :total_user_count => {
      :icon => "table",
      :desc => N_("Registered Users"),
      :unit => N_("users")
    },
    :today_user_count => {
      :icon => "table_lightning",
      :desc => N_("Today's Access"),
      :unit => N_("users")
    },
    :total_blog_count => {
      :icon => "database",
      :desc => N_("Total Entries"),
      :unit => N_("entries")
    },
    :today_blog_count => {
      :icon => "database_lightning",
      :desc => N_("Today's Entries"),
      :unit => N_("entries")
    },
    :writer_at_month => {
      :icon => "database_edit",
      :desc => N_("Posted entries or comments during the recent month"),
      :unit => N_("users")
    },
    :user_access_at_month => {
      :icon => "database_go",
      :desc => N_("Average access during the recent month"),
      :unit => N_("users")
    }
  }.freeze

  def self.get_by_date date
    SiteCount.find(:first,
                   :conditions => ["DATE_FORMAT(created_on, '%Y-%m-%d') = ?", date.strftime('%Y-%m-%d')]) || SiteCount.new #"
  end

  # TODO 回帰テストを書く
  def self.create_data
    now = Time.now
    SiteCount.delete_all ["created_on like ?", now.strftime("%Y-%m-%d") + "%"]
    SiteCount.create(
      :total_user_count => User.active.count,
      :today_user_count => UserAccess.last_access_gt(now.beginning_of_day).count,
      :total_blog_count => BoardEntry.count,
      :today_blog_count => BoardEntry.scoped(:conditions => ["created_on > ?", now.beginning_of_day]).count,
      :writer_at_month =>  calc_writer_at_month(now),
      :user_access_at_month => calc_user_access_at_month(now),
      :active_users => UserAccess.active_user.last_access_gt(now.beginning_of_day.ago(10.day)).count,
      :write_users_all => BoardEntry.active_user.publication_type_eq('public').diary.count(:distinct => true, :select => 'user_id'),
      :write_users_with_pvt => BoardEntry.active_user.diary.count(:distinct => true, :select => 'user_id'),
      :write_users_with_bbs => BoardEntry.active_user.count(:distinct => true, :select => 'user_id'),
      :comment_users => BoardEntryComment.active_user.count(:distinct => true, :select => 'user_id'),
      :portrait_users => Picture.active_user.count(:distinct => true, :select => 'user_id')
    )
  end

  private
  # ここ一ヶ月以内にコメントか記事を投稿したユーザー数
  def self.calc_writer_at_month time_now
    user_ids = BoardEntry.active_user.scoped(:conditions => ["created_on BETWEEN ? and ?", time_now.last_month, time_now]).map(&:user_id)
    user_ids << BoardEntryComment.active_user.scoped(:conditions => ["created_on BETWEEN ? and ?", time_now.last_month, time_now]).map(&:user_id)
    user_ids.flatten.uniq.size
  end

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
