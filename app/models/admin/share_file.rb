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

class Admin::ShareFile < ShareFile
  N_('Admin::ShareFile|File name')
  N_('Admin::ShareFile|Owner symbol')
  N_('Admin::ShareFile|Owner symbol type')
  # TODO lib/symbol.rbに記述してみたが、N_がundefinedとなってしまう。解決方法を探る
  N_('Symbol|Type|user')
  N_('Symbol|Type|group')
  N_('Admin::ShareFile|Description')
  N_('Admin::ShareFile|Date')
  N_('Admin::ShareFile|User')
  N_('Admin::ShareFile|Category')
  N_('Admin::ShareFile|Total count')
  N_('Admin::ShareFile|Content type')
  N_('Admin::ShareFile|Publication type')
  # TODO app/model/publication.rbに記述してみたが、N_がundefinedとなってしまう。解決方法を探る
  N_('Publication type|public')
  N_('Publication type|protected')
  N_('Publication type|private|uid')
  N_('Publication type|private|gid')
  N_('Admin::ShareFile|Publication symbols type')

  def self.search_columns
    %w(file_name description category)
  end

  def topic_title
    file_name[/.{1,10}/] + "..."
  end
end
