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

module UserMailerHelper

  def convert_plain entry
    return '' if entry.blank?
    html = if entry.editor_mode == 'hiki'
             HikiDoc.new((entry.contents || ''), Regexp.new(SkipEmbedded::InitialSettings['not_blank_link_re'])).to_html
           else
             entry.contents
           end
    plain = strip_tags(html).strip.gsub(/\t/) { '' }
    plain = plain.scan(/.{0,200}/m).first.gsub('&nbsp;',' ').gsub("&amp;", "&").gsub("&quot;",'"').gsub("&gt;", '>').gsub("&lt;", '<')
    plain.gsub(/^(.*)/) { "    #{$1}" }
  end
end
