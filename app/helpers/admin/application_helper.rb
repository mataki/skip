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

module Admin::ApplicationHelper
  def generate_tab_menu menu_source, option = {}
    output = ''
    output << '<ul>'
    output << generate_tab_link( _('データ管理'), admin_accounts_path, true )
    output << '</ul>'
  end

  def generate_admin_box_menu selected_path = nil
    output = ''
    output << '<ul>'
    output << generate_box_menu_link( _('account'), admin_accounts_path, admin_accounts_path == selected_path )
    output << generate_box_menu_link( _('user'), admin_users_path, admin_users_path == selected_path )
    output << generate_box_menu_link( _('bookmark'), admin_bookmarks_path , admin_bookmarks_path == selected_path)
    output << generate_box_menu_link( _('board entry'), admin_board_entries_path, admin_board_entries_path == selected_path )
    output << generate_box_menu_link( _('share file'), admin_share_files_path, admin_share_files_path == selected_path )
    output << generate_box_menu_link( _('group'), admin_groups_path, admin_groups_path == selected_path )
    output << '</ul>'
  end

  private
  def generate_box_menu_link(name, path, selected = false, html_options = nil)
    if selected
      "<li>#{icon_tag('bullet_red')}<b>#{name}</b></li>"
    else
      "<li>#{icon_tag('bullet_blue')}#{link_to(name, path, html_options)}</b></li>"
    end
  end

  def generate_tab_link(name, path, selected = false, html_options = nil)
    html_option = {:class => 'selected'} if selected
    "<li>#{link_to('<span>' + name + '</span>', path, html_option)}</li>"
  end
end
