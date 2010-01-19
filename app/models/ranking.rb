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

class Ranking < ActiveRecord::Base
 
  validates_uniqueness_of :url, :scope => [:extracted_on, :contents_type]

  def self.monthly(contents_type, year, month)
    sql = <<-SQL
      SELECT 
        recent.url, recent.title, recent.author, recent.author_url, recent. extracted_on,
        COALESCE(recent.amount - previous.amount, recent.amount) AS amount,
        recent.contents_type
      FROM (
          SELECT url, title, author, author_url, MAX(extracted_on) AS extracted_on, MAX(amount) AS amount, contents_type
          FROM rankings 
          WHERE rankings.contents_type = :contents_type
            AND rankings.extracted_on BETWEEN :beginning_of_month AND :end_of_month
          GROUP BY url
        ) AS recent 
      LEFT OUTER JOIN (
          SELECT url, title, author, author_url, MAX(extracted_on) AS extracted_on, MAX(amount) AS amount, contents_type
          FROM rankings 
          WHERE rankings.contents_type = :contents_type
            AND rankings.extracted_on <= :end_of_month_ago_1_month 
          GROUP BY url
      ) AS previous
        ON recent.url = previous.url 
      ORDER BY amount DESC
      LIMIT 10
    SQL
    time = Time.local(year, month)
    Ranking.find_by_sql([sql, { :contents_type => contents_type.to_s,
                                :beginning_of_month => time.beginning_of_month,
                                :end_of_month => time.end_of_month,
                                :end_of_month_ago_1_month => time.end_of_month.ago(1.month) }])
  end

  def self.total(contents_type)
    Ranking.find :all, :conditions => ["contents_type = ? ", contents_type.to_s ],
      :select => "url, title, author, author_url, MAX(extracted_on) AS extracted_on, MAX(amount) AS amount, contents_type",
      :limit => 10, :group => "url", :order => "amount DESC" 
  end

  def self.extracted_dates
    Ranking.all(:select => "DISTINCT DATE_FORMAT(extracted_on, '%Y-%m') as extracted_month", :order => 'extracted_on desc').map { |r| r.extracted_month }
  end
end
