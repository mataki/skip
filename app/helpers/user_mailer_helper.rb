# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
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

module UserMailerHelper

  def convert_plain entry
    return '' if entry.blank?
    contents = if entry.editor_mode == 'hiki'
                 strip_tags(HikiDoc.new((entry.contents || ''), Regexp.new(SkipEmbedded::InitialSettings['not_blank_link_re'])).to_html)
               else
                 strip_tags entry.contents
               end
    truncate(contents, :length => 100)
  end
end
