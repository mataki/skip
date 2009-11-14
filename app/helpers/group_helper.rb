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

module GroupHelper
  include BoardEntriesHelper
  include UsersHelper
  include GroupsHelper

  # 管理メニューの生成
  def get_group_manage_menu_items selected_menu
    @@menus = [{:name => _("Edit Group Information"), :menu => "manage_info" },
               {:name => _("Manage Members"),       :menu => "manage_participations"} ]
    @@menus << {:name => _("Approve Member"),     :menu => "manage_permit" } if @group.protected?

    get_menu_items @@menus, selected_menu, "manage"
  end

  def get_select_user_options owners
    options_hash = {}
    owners.each { |owner| options_hash.store(owner.name, owner.id) }
    options_hash
  end

  def group_tab_menu_source group
    tab_menu_source = []
    tab_menu_source << {:label => _('Top'), :options => {:controller => 'group', :action => 'show'}}
    tab_menu_source << {:label => _('Members'), :options => {:controller => 'group', :action => 'users'}} unless group.group_participations.active.except_owned.empty?
    tab_menu_source << {:label => _('Forums'), :options => {:controller => 'group', :action => 'bbs', :sort_type => 'date', :type => 'entry'}} unless BoardEntry.owned(group).accessible(current_user).empty?
    tab_menu_source << {:label => _('Shared Files'), :options => {:controller => 'share_file', :action => "list"}} unless ShareFile.owned(group).accessible(current_user).empty?
    tab_menu_source << {:label => _('Admin'), :options => {:controller => 'group', :action => 'manage'}} if group.administrator?(current_user)
    tab_menu_source
  end
end
