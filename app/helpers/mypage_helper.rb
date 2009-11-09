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
      title_tag = content_tag(:h2, :class => 'topix_title'){ icon_tag(icon) + h(label) }
      all_link_tag = content_tag(:div, :style => "position: absolute; top: 5px; right: 10px; font-size: 14px;") { link_to(_('[See all]'), all_url) }
      all_url ? "#{title_tag}#{all_link_tag}" : title_tag
    end
  end

  # 送信先の加工
  def get_link_to_name(mail, item)
    item ? item_link_to(item) : h(mail.to_address_name)
  end

  # タイトルの加工
  def get_link_to_title(mail, board_entry)
    board_entry ? entry_link_to(board_entry,{:truncate => 25 }) :  h(mail.title)
  end

  # 送信日の加工
  def get_send_date(mail)
    mail.send_flag ?  Time.parse(mail.mail_updated_on).strftime(_("%c")) : _("Waiting to be Sent")
  end

  # 管理メニューの生成
  def get_manage_menu_items selected_menu
    @@menus = []
    @@menus << {:name => _("Edit Profile"), :menu => "manage_profile" }
    @@menus << {:name => _("Change Password"), :menu => "manage_password" } if SkipEmbedded::InitialSettings['password_edit_setting'] and login_mode?(:password)
    @@menus << {:name => _("Change Email Address"), :menu => "manage_email" } if SkipEmbedded::InitialSettings['mail']['show_mail_function']
    @@menus << {:name => _("Change OpenID URL"), :menu => "manage_openid" } if login_mode?(:free_rp)
    @@menus << {:name => _("Change Profile Picture"), :menu => "manage_portrait" } if Admin::Setting.enable_change_picture
    @@menus << {:name => _("Customize"), :menu => "manage_customize" }
    @@menus << {:name => _("Email Notification"), :menu => "manage_message" } if SkipEmbedded::InitialSettings['mail']['show_mail_function']
    get_menu_items @@menus, selected_menu, "manage"
  end

  # 履歴メニューの生成
  def get_record_menu_items selected_menu
    @@record_menus = []
    @@record_menus << {:name => _("Email History"), :menu => "record_mail" } if SkipEmbedded::InitialSettings['mail']['show_mail_function']
    @@record_menus << {:name => _("History of Entries"), :menu => "record_post" }

    get_menu_items @@record_menus, selected_menu, "manage"
  end
end
