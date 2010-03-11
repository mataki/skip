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

module GroupsHelper

  # 参加状態の条件によって表示内容を変更
  def participation_state group, user_id, options={}
    if participation = group.group_participations.detect{|participation| participation.user_id == user_id }
      if participation.owned?
        icon_tag('group_key') + _('Administrator')
      elsif participation.waiting?
        icon_tag('hourglass') + _('Waiting for approval of the administrator')
      else
        icon_tag('group') + _('Member')
      end
    else
      if options[:blank_unjoined].blank?
        icon_tag('group_error') + _('Unjoined')
      end
    end
  end

  # エントリ数、エントリ最終更新日時より活性状況を判定
  def upsurge_frequency entries
    (entries.count > 50) && (Time.now.ago(7.day) < entries.last.last_updated) unless entries.empty?
  end

  def get_group_manage_menu_items selected_menu
    @@menus = [{:name => _("Edit Group Information"), :menu => "manage_info" }]
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
    tab_menu_source << {:label => _('Top'), :options => tenant_group_url(current_tenant, current_target_group)}
    tab_menu_source << {:label => _('Members'), :options => {:controller => 'group', :action => 'users', :gid => group.gid}} unless group.group_participations.active.except_owned.empty?
    tab_menu_source << {:label => _('Forums'), :options => {:controller => 'group', :action => 'bbs', :gid => group.gid, :sort_type => 'date', :type => ''}} unless BoardEntry.owned(group).accessible(current_user).empty?
    tab_menu_source << {:label => _('Shared Files'), :options => {:controller => 'share_file', :action => "list", :gid => group.gid}} unless current_target_group.owner_share_files.accessible(current_user).empty?
    tab_menu_source << {:label => _('Admin'), :options => manage_tenant_group_url(current_tenant, current_target_group)} if group.owned?(current_user)
    tab_menu_source
  end
end
