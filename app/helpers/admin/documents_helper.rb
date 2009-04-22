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

module Admin::DocumentsHelper
  def generate_box_menu
    output = ''
    output << '<ul>'
    Admin::DocumentsController::CONTENT_NAMES.each do |name|
      output << generate_box_menu_link( _("Admin::DocumentsController|#{name}"), admin_documents_path(name), request.url == admin_documents_url(name) )
    end
    output << '</ul>'
  end
end
