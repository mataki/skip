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

class History < ActiveRecord::Base
  belongs_to :page
  belongs_to :content
  belongs_to :user

  validates_associated :content
  validates_presence_of :user_id
  after_save :update_page_updated_at

  named_scope :heads, lambda{|*opts|
    heads_sql = <<-SQL
  SELECT hs.id
  FROM   #{quoted_table_name} AS hs
  INNER JOIN (
    SELECT
      h.page_id AS page_id,
      MAX(h.revision) AS revision
    FROM histories AS h
    GROUP BY h.page_id
  ) AS heads
  ON hs.page_id = heads.page_id AND hs.revision = heads.revision
SQL
    # or/ {:conditions => ["#{quoted_table_name}.id IN (#{heads_sql})"]}
    ids = connection.select_all(heads_sql).map{|h| Integer(h["id"]) }
    {:conditions => ["#{quoted_table_name}.id IN (?)", ids ]}
  }

  def self.find_all_by_head_content(keyword, only_head = true)
    heads.find(:all, :include => :content,
                     :conditions => ["contents.data LIKE ?", "%#{keyword}%"])
  end

  private
  def update_page_updated_at
    page.touch
    page.last_modified_user_id = self.user_id
    page.save
  end

end
