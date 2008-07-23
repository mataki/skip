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

class BatchMakeRanking < BatchBase

   execute_day = "20080715"

#  アクセス数  entry_access_rankings
   BoardEntryPoint.find(:all, :conditions => ["today_access_count > 0 AND DATE_FORMAT(updated_on,'%Y%m%d') = ?", execute_day]).each do |record|
     Ranking.create(
       :contents_type => "entry_access",
       :extracted_on => execute_day,
       :url => "#{ENV['SKIP_URL']}/page/#{record.board_entry.id}",
       :title => record.board_entry.title,
       :author => record.board_entry.user.name,
       :author_url => "#{ENV['SKIP_URL']}/user/#{record.board_entry.user.nickname}",
       :amount => record.access_count
     )
   end

#  コメント数  entry_comment_rankings
   BoardEntry.find(:all, :conditions => ["board_entry_comments_count > 0 and date_format(updated_on,'%y%m%d') = ?", execute_day]).each do |record|
     ranking.create(
       :url => "#{ENV['skip_url']}/page/#{record.id}",
       :contents_type => "entry_comment",
       :title => record.title,
       :author => record.user.name,
       :author_url => "#{ENV['skip_url']}/user/#{record.user.get_uid}",
       :extracted_on => execute_day,
       :amount => record.board_entry_comments_count
     )
   end

#  へー  entry_he_rankings
   BoardEntryPoint.find(:all, :conditions => ["point > 0 AND DATE_FORMAT(updated_on,'%Y%m%d') = ?", execute_day]).each do |record|
     Ranking.create(
       :url => "#{ENV['SKIP_URL']}/page/#{record.board_entry.id}", 
       :contents_type => "entry_he",
       :title => record.board_entry.title,
       :author => record.board_entry.user_id,
       :author_url => "#{ENV['SKIP_URL']}/user/#{record.board_entry.user.get_uid}",
       :extracted_on => execute_day,
       :amount => record.point
     )
   end

#    投稿数 entry_post_rankings
   BoardEntry.find(:all, :select =>"user_id, count(*) as entry_count", :conditions => ["entry_type = 'DIARY' AND DATE_FORMAT(updated_on,'%Y%m%d') = ?", execute_day], :group => "user_id").each do |record|
     Ranking.create(
       :url => "#{ENV['SKIP_URL']}/user/#{record.user.get_uid}",
       :contents_type => "user_entry",
         :title => record.user.name,
         :author => "",
         :author_url => "",
         :extracted_on => execute_day,
         :amount => record.entry_count
     )
   end

#  訪問者数 user_access_rankings
   UserAccess.find(:all, :conditions => ["access_count > 0 AND DATE_FORMAT(updated_on,'%Y%m%d') = ?", execute_day]).each do |record|
     Ranking.create(
       :url => "#{ENV['SKIP_URL']}/user/#{record.user.get_uid}",
       :contents_type => "user_access",
         :title => record.user.name,
         :author => "",
         :author_url => "",
         :extracted_on => execute_day,
         :amount => record.access_count
     )
   end

end
