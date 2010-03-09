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

module UsersHelper
  # ユーザのページへのリンク
  def user_link_to user, options = {}
    output_text = ""
    output_text << icon_tag('user_suit') if options[:image_on]
    output_text << title = h(user.name)

    link = link_to(output_text, {:controller => 'user', :action => 'show', :uid => user.uid}, {:title => title})
    if options[:with_prefix]
      "by #{link}"
    else
      link
    end
  end

  def user_link_to_with_portrait user, options = {}
    options = {:width => 80, :height => 80}.merge(options)
    link_to show_picture(user, options), {:controller => '/user', :action => 'show', :uid => user.uid}, {:title => h(user.name)}
  end
end
