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

module MypageHelper

  # タイトルバーの表示
  def show_title_bar(icon, label, all_url = nil)
    content_tag(:div, :style => "position: relative; _width: 100%;") do
      title_tag = content_tag(:h2, :class => 'topix_title'){ icon_tag(icon) + link_to_unless(all_url.blank?, h(label), all_url) }
    end
  end

  # 管理メニューの生成
  def get_manage_menu_items selected_menu
    @@menus = []
    @@menus << {:name => _("Edit Profile"), :menu => "manage_profile" }
    @@menus << {:name => _("Change Profile Picture"), :menu => "manage_portrait" } if Admin::Setting.enable_change_picture
    @@menus << {:name => _("Change Password"), :menu => "manage_password" } if SkipEmbedded::InitialSettings['password_edit_setting'] and login_mode?(:password)
    @@menus << {:name => _("Change Email Address"), :menu => "manage_email" } if SkipEmbedded::InitialSettings['mail']['show_mail_function']
    @@menus << {:name => _("Change OpenID URL"), :menu => "manage_openid" } if login_mode?(:free_rp)
    @@menus << {:name => _("Customize"), :menu => "manage_customize" }
    @@menus << {:name => _("Email Notification"), :menu => "manage_message" } if SkipEmbedded::InitialSettings['mail']['show_mail_function']
    get_menu_items @@menus, selected_menu, "manage"
  end

  def system_message_links
    return @system_message_links if @system_message_links
    system_message_links = []

    if system_notice = SkipEmbedded::InitialSettings['system_notice'] and !system_notice['title'].blank?
      system_message_links << link_to(icon_tag('information') + h(system_notice['title']), system_notice['url'])
    end

    if Admin::Setting.enable_password_periodic_change && current_user.password_expires_at.ago(2.week) < Time.now
      system_message_links << link_to(icon_tag('bullet_error') + _('The password expiration date (%s) approaches') % current_user.password_expires_at.ago(1.day).strftime(_('%B %d %Y')), url_for(:controller => 'mypage', :action => 'manage', :menu => 'manage_password'))
    end

    unless current_user.picture
      system_message_links << link_to(icon_tag('picture') + _("Change your profile picture!"), {:controller => "mypage", :action => "manage", :menu => "manage_portrait"})
    end

    message_array = Message.get_message_array_by_user_id(current_user.id)
    message_array.each do |message|
      if message_type = Message::MESSAGE_TYPES[message[:message_type]]
        system_message_links << link_to(icon_tag(message_type[:icon_name]) + h(message[:message]), message[:link_url])
      end
    end

    Group.owned(current_user).each do |group|
      unless group.group_participations.waiting.empty?
        system_message_links << link_to(icon_tag('group_add') + _("New user is waiting for approval in %s.") % group.name, {:controller => 'group', :action => 'manage', :gid => group.gid, :menu => 'manage_permit'})
      end
    end
    @system_message_links = system_message_links
  end
end
