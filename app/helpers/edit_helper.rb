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

module EditHelper
  def share_files_url symbol
    symbol_type, symbol_id = Symbol.split_symbol symbol
    if symbol_type == 'uid'
      url_for :controller => 'user', :action => 'share_file', :uid => symbol_id, :format => 'js'
    elsif symbol_type == 'gid'
      url_for :controller => 'group', :action => 'share_file', :gid => symbol_id, :format => 'js'
    else
      ''
    end
  end
end
