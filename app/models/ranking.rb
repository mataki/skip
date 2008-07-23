# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008 TIS Inc.
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

class Ranking < ActiveRecord::Base
  def self.monthly(contents_type, year, month)
    sql = <<-SQL
      select
        rankings.url,
        rankings.title,
        rankings.author,
        rankings.author_url,
        rankings. extracted_on,
        coalesce(rankings.amount - previous_rankings.amount, rankings.amount) as amount,
        rankings.contents_type
      from (
        select rankings.* 
        from (
          select url, max(contents_type) as contents_type, max(extracted_on) as extracted_on 
          from rankings 
          where rankings.contents_type = :contents_type
            and rankings.extracted_on between :beginning_of_month and :end_of_month
          group by url
        ) as recentry_rankings 
        left outer join rankings 
          on recentry_rankings.url = rankings.url 
          and recentry_rankings.contents_type = rankings.contents_type 
          and recentry_rankings.extracted_on = rankings.extracted_on 
      ) as rankings 
      left outer join (
        select rankings.* 
        from (
          select url, max(contents_type) as contents_type, max(extracted_on) as extracted_on 
          from rankings 
          where rankings.contents_type = :contents_type
            and rankings.extracted_on <= :end_of_month_ago_1_month
          group by url
        ) as recentry_rankings 
        left outer join rankings 
          on recentry_rankings.url = rankings.url 
          and recentry_rankings.contents_type = rankings.contents_type 
          and recentry_rankings.extracted_on = rankings.extracted_on 
      ) as previous_rankings
        on rankings.url = previous_rankings.url 
        and rankings.contents_type = previous_rankings.contents_type
      order by amount desc
      limit 10
    SQL
    time = Time.local(year, month)
    Ranking.find_by_sql([sql, { :contents_type => contents_type.to_s,
                                :beginning_of_month => time.beginning_of_month,
                                :end_of_month => time.end_of_month,
                                :end_of_month_ago_1_month => time.end_of_month.ago(1.month) }])
  end

  def self.total(contents_type)
    sql = <<-SQL
      select rankings.* 
      from (
        select url, max(contents_type) as contents_type, max(extracted_on) as extracted_on 
        from rankings 
        where rankings.contents_type = :contents_type
        group by url
      ) as recentry_rankings 
      left outer join rankings 
        on recentry_rankings.url = rankings.url 
        and recentry_rankings.contents_type = rankings.contents_type 
        and recentry_rankings.extracted_on = rankings.extracted_on 
      order by amount desc
      limit 10
    SQL
    Ranking.find_by_sql([sql, { :contents_type => contents_type.to_s }])
  end
end
