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

require File.expand_path(File.dirname(__FILE__) + "/batch_base")

class BatchMakePopularBoookmarks < BatchBase

  #最近人気の記事用(ある日から1週間以内であるブックマークに対してコメントがいくつついたかを数える)
  #今は全部のブックマークに対してやってるけど、countでorderして、上位20件ってかける？。havingはかけないっぽい
  def self.execute options
    bookmark_counts = BookmarkComment.count(:group => "bookmark_id", :select => "bookmark_id" , :conditions => ["created_on > ?", Date.today-6])
    PopularBookmark.delete_all ["date = ?", Date.today]
    bookmark_counts.each do |bookmark_count|
      PopularBookmark.create(:bookmark_id => bookmark_count.first, :count => bookmark_count.last, :date => Date.today)
    end
  end
end

BatchMakePopularBoookmarks.execution
