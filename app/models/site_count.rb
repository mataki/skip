# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
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
end
