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

require File.expand_path(File.dirname(__FILE__) + "/batch_base")
require 'fileutils'

class BatchDeleteCache < BatchBase
  @@deleter = []
  def self.execute options=nil
    @@deleter.each do |deleter|
      deleter.new.execute
    end
  end

  def self.add_deleter(deleter)
    @@deleter << deleter
  end

  class DefaultDeleter
    def all_ids
      @all_ids if @all_ids
      con = self.class.name.underscore.split('/').last.split("_")[0..-2].join("_").classify.constantize
      @all_ids = con.find(:all, :select => "id", :order => "id asc").map{|item| item.id}
    rescue NameError => e
      BatchDeleteCache.log_warn e.message
      @all_ids = []
    end

    def root_cache_path
      INITIAL_SETTINGS['cache_path']
    end

    def dir_id(id)
      (id/1000).to_s.rjust(4,'0')
    end

    def delete(file_path)
      File.delete file_path
      BatchDeleteCache.log_info "delete #{file_path}"
    rescue Errno::ENOENT => e
    end

    def delete_cache(id)
      delete(cache_path(id))
    end

    def delete_meta(id)
      delete(meta_path(id))
    end

    def execute
      unless all_ids.empty?
        ((1..all_ids.last).to_a - all_ids).each do |i|
          delete_cache(i)
          delete_meta(i)
        end
      end
    end
  end

  class BoardEntryDeleter < DefaultDeleter
    BatchDeleteCache.add_deleter self
    def cache_path(id)
      File.join(root_cache_path, "entry", dir_id(id), "#{id}.html")
    end

    def meta_path(id)
      File.join("#{root_cache_path}_meta", "entry", dir_id(id), "#{id}.html")
    end
  end

#   class BookmarkDeleter < DefaultDeleter
#     BatchDeleteCache.add_deleter self
#     def cache_path(id)
#       File.join(root_cache_path, "bookmark", dir_id(id), "#{id}.html")
#     end

#     def meta_path(id)
#       File.join("#{root_cache_path}_meta", "bookmark", dir_id(id), "#{id}.html")
#     end
#   end

  class GroupDeleter < DefaultDeleter
    BatchDeleteCache.add_deleter self
    def cache_path(id)
      File.join(root_cache_path, "group", dir_id(id), "#{id}.html")
    end

    def meta_path(id)
      File.join("#{root_cache_path}_meta", "group", dir_id(id), "#{id}.html")
    end
  end

#   class UserDeleter < DefaultDeleter
#     BatchDeleteCache.add_deleter self
#     def cache_path(id)
#       File.join(root_cache_path, "user", dir_id(id), "#{id}.html")
#     end

#     def meta_path(id)
#       File.join("#{root_cache_path}_meta", "user", dir_id(id), "#{id}.html")
#     end
#   end
end

BatchDeleteCache.execution unless RAILS_ENV == 'test'
