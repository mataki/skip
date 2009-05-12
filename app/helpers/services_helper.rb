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

module ServicesHelper
  include ApplicationHelper
  def application_link
    if collaboration_apps = INITIAL_SETTINGS['collaboration_apps']
      application_links = collaboration_apps.values.map{|m| link_to( m['name'], m['url'] )} || []
      application_links.unshift link_to( 'SKIP', root_url ) unless application_links.empty?
      application_links.join(' | ')
    end
  end
end
