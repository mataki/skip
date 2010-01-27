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

class Admin::UserUid < UserUid
  N_('Admin::UserUid|Uid')
  N_('Admin::UserUid|Uid description')
  N_('Admin::UserUid|Uid type')

  def after_update
    if uid_changed?
      self.class.rename(uid_was, uid)
      self.user.delete_auth_tokens!
      self.user.update_attribute(:updated_on, Time.now)
    end
  end

  def after_create
    if master = self.class.find(:first, :conditions => { :uid_type => UserUid::UID_TYPE[:master], :user_id => user_id }) and
        self.class.find(:all, :conditions => { :uid_type => UserUid::UID_TYPE[:username], :user_id => user_id }).size == 1
      self.class.rename(master.uid, uid)
      self.user.delete_auth_tokens!
      self.user.update_attribute(:updated_on, Time.now)
    end
  end

  def topic_title
    user.name
  end

  def self.rename(from, to)
    ActiveRecord::Base.connection.execute("update board_entries set symbol = 'uid:#{to}' where symbol = 'uid:#{from}'")
    ActiveRecord::Base.connection.execute("update board_entries set publication_symbols_value = replace(publication_symbols_value, 'uid:#{from}', 'uid:#{to}') where publication_symbols_value like '%uid:#{from}%'")
    ActiveRecord::Base.connection.execute("update board_entries set contents = replace(contents, 'uid:#{from}', 'uid:#{to}') where editor_mode = 'hiki' and contents like '%uid:#{from}%'")
    ActiveRecord::Base.connection.execute("update board_entry_comments set contents = replace(contents, 'uid:#{from}', 'uid:#{to}') where contents like '%uid:#{from}%'")
    ActiveRecord::Base.connection.execute("update chains set comment = replace(comment, 'uid:#{from}', 'uid:#{to}') where comment like '%uid:#{from}%'")
    ActiveRecord::Base.connection.execute("update entry_editors set symbol = 'uid:#{to}' where symbol = 'uid:#{from}'")
    ActiveRecord::Base.connection.execute("update entry_publications set symbol = 'uid:#{to}' where symbol = 'uid:#{from}'")
    ActiveRecord::Base.connection.execute("update groups set description = replace(description, 'uid:#{from}', 'uid:#{to}') where description like '%uid:#{from}%'")
    ActiveRecord::Base.connection.execute("update share_file_publications set symbol = 'uid:#{to}' where symbol = 'uid:#{from}'")
    ActiveRecord::Base.connection.execute("update share_files set owner_symbol = 'uid:#{to}' where owner_symbol = 'uid:#{from}'")
    ActiveRecord::Base.connection.execute("update share_files set publication_symbols_value = replace(publication_symbols_value, 'uid:#{from}', 'uid:#{to}') where publication_symbols_value like '%uid:#{from}%'")
    ActiveRecord::Base.connection.execute("update bookmarks set url = replace(url, '/user/#{from}', '/user/#{to}') where url = '/user/#{from}'")
  end
end
