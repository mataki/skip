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
  named_scope :by_contents_type, proc{|contents_type| {:conditions => {:contents_type => contents_type.to_s}} }
  named_scope :max_amount_by_url, {:select => 'id, url, title, max(extracted_on) as extracted_on, amount', :group => :url}
  named_scope :top_10, {:order => 'amount desc', :limit => 10}

  def self.all(contents_type)
    # TODO 通常のallメソッドと名前かぶるの変える
    by_contents_type(contents_type).max_amount_by_url.top_10
  end

  def self.monthly(contents_type, year, month)
  end
end
