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
end
