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

module EditHelper
  def send_mail_check_box_tag
    if SkipEmbedded::InitialSettings['mail']['show_mail_function']
      result = ''
      result << check_box(:board_entry, :send_mail)
      result << label(:board_entry, :send_mail, _('Send email to accessible members'))
      content_tag :span, result, :class => 'send_mail_field'
    end
  end

  private
  def share_files_url symbol
    symbol_type, symbol_id = Symbol.split_symbol symbol
    raise ArgumentError, 'Symbol type is invalid.' unless %w(uid gid).include?(symbol_type)
    url_for :controller => 'share_file', :action => 'list', symbol_type.to_sym => symbol_id, :format => 'js'
  end
end
