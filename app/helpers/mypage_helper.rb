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
  def show_title_bar(icon, label, all_url)
    <<-EOS
<div style="position: relative; _width: 100%;">
  <h2 class="topix_title">#{icon_tag(icon) + h(label)}</h2>
  <div style="position: absolute; top: 5px; right: 10px; font-size: 14px;">#{link_to('[すべて見る]', all_url)}</div>
</div>
    EOS
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
    mail.send_flag ?  Time.parse(mail.mail_updated_on).strftime("%Y年%m月%d日 %H時%M分") : "送信待ち"
  end

  # 管理メニューの生成
  def get_manage_menu_items selected_menu
    @@menus = []
    @@menus << {:name => "プロフィール変更", :menu => "manage_profile" }
    @@menus << {:name => "パスワード変更", :menu => "manage_password" } if INITIAL_SETTINGS['password_edit_setting'] and login_mode?(:password)
    @@menus << {:name => "メールアドレス変更", :menu => "manage_email" } if Admin::Setting.mail_function_setting
    @@menus << {:name => "OpenID URL変更", :menu => "manage_openid" } if login_mode?(:free_rp)
    @@menus << {:name => "プロフィール画像変更", :menu => "manage_portrait" }
    @@menus << {:name => "画面デザイン変更", :menu => "manage_customize" }
    @@menus << {:name => "アンテナの整備", :menu => "manage_antenna" }
    @@menus << {:name => "メール通知設定", :menu => "manage_message" } if Admin::Setting.mail_function_setting
    get_menu_items @@menus, selected_menu, "manage"
  end

  # 履歴メニューの生成
  def get_record_menu_items selected_menu
    @@record_menus = []
    @@record_menus << {:name => "メール送信履歴", :menu => "record_mail" } if Admin::Setting.mail_function_setting
    @@record_menus << {:name => "記事履歴", :menu => "record_post" }

    get_menu_items @@record_menus, selected_menu, "manage"
  end

end
