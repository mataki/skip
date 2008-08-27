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

class Admin::UserUid < UserUid
  N_('Admin::UserUid|Uid')
  N_('Admin::UserUid|Uid type')

  def after_save
    ActiveRecord::Base.connection.execute("update board_entries set symbol = 'uid:#{uid}' where symbol = 'uid:#{uid_was}'")
    ActiveRecord::Base.connection.execute("update users set introduction = replace(introduction, 'uid:#{uid_was}', 'uid:#{uid}') where introduction like '%uid:#{uid_was}%'")
    ActiveRecord::Base.connection.execute("update user_profiles set introduction = replace(introduction, 'uid:#{uid_was}', 'uid:#{uid}') where introduction like '%uid:#{uid_was}%'")
    ActiveRecord::Base.connection.execute("update board_entries set symbol = 'uid:#{uid}' where symbol = 'uid:#{uid_was}'")
    ActiveRecord::Base.connection.execute("update board_entries set publication_symbols_value = replace(publication_symbols_value, 'uid:#{uid_was}', 'uid:#{uid}') where publication_symbols_value like '%uid:#{uid_was}%'")
    ActiveRecord::Base.connection.execute("update board_entries set contents = replace(contents, 'uid:#{uid_was}', 'uid:#{uid}') where editor_mode = 'hiki' and contents like '%uid:#{uid_was}%'")
    ActiveRecord::Base.connection.execute("update board_entry_comments set contents = replace(contents, 'uid:#{uid_was}', 'uid:#{uid}') where contents like '%uid:#{uid_was}%'")
    ActiveRecord::Base.connection.execute("update chains set comment = replace(comment, 'uid:#{uid_was}', 'uid:#{uid}') where comment like '%uid:#{uid_was}%'")
    ActiveRecord::Base.connection.execute("update entry_editors set symbol = 'uid:#{uid}' where symbol = 'uid:#{uid_was}'")
    ActiveRecord::Base.connection.execute("update entry_publications set symbol = 'uid:#{uid}' where symbol = 'uid:#{uid_was}'")
    ActiveRecord::Base.connection.execute("update groups set description = replace(description, 'uid:#{uid_was}', 'uid:#{uid}') where description like '%uid:#{uid_was}%'")
    ActiveRecord::Base.connection.execute("update messages set link_url = replace(link_url, '/user/#{uid_was}', '/user/#{uid}') where link_url like '/user/#{uid_was}%'")
    ActiveRecord::Base.connection.execute("update share_file_publications set symbol = 'uid:#{uid}' where symbol = 'uid:#{uid_was}'")
    ActiveRecord::Base.connection.execute("update share_files set owner_symbol = 'uid:#{uid}' where owner_symbol = 'uid:#{uid_was}'")
    ActiveRecord::Base.connection.execute("update share_files set publication_symbols_value = replace(publication_symbols_value, 'uid:#{uid_was}', 'uid:#{uid}') where publication_symbols_value like '%uid:#{uid_was}%'")
    ActiveRecord::Base.connection.execute("update mails set from_user_id = '#{uid}' where from_user_id = '#{uid_was}'")
    ActiveRecord::Base.connection.execute("update mails set to_address_symbol = 'uid:#{uid}' where to_address_symbol = 'uid:#{uid_was}'")
    ActiveRecord::Base.connection.execute("update bookmarks set url = replace(url, '/user/#{uid_was}', '/user/#{uid}') where url = '/user/#{uid_was}'")
    ActiveRecord::Base.connection.execute("update antenna_items set value = 'uid:#{uid}' where value = 'uid:#{uid_was}'")
  end
end
