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

module GroupHelper
  include BoardEntriesHelper
  include UsersHelper

  # グループのサマリに出す状態を状況に応じて出力する
  # 表示文字列と、可能な操作の文字列のペアを返す
  def generate_visitor_state participation
    state = ''
    if not participation
      state = 'まだ申し込みしていません'
    elsif participation.owned?
      state = '管理者です！'
    elsif participation.waiting?
      state = '参加承認待ち！'
    else
      state = '参加中です！'
    end

    button = ""
    if participation
      if !participation.owned?
        button << form_tag(:action=> 'leave')
        button << submit_tag('退会する', {:onclick=>'return confirm("本当に退会しますか？");'})
        # FIXME form_tag の 閉じは end にしたい
        button << "</form>"
      end
    else
      button << link_to('[参加申込みへ]', {:action=>"new_participation"}, {:class => "nyroModal"})
    end

    return state, button
  end

  # グループのサマリに出すお知らせを状況に応じて出力する
  # 表示したい文字列の配列を返す
  def generate_informations group, participation
    informations = []
    if group.protected?
      informations << icon_tag('key') + "このグループは参加するのにグループ管理者の承認が必要です。"
    else
      informations << icon_tag('bullet_blue') + "このグループへの参加は自由です。"
    end

    unless participation
      url_param = {:controller => "group", :action => "new_participation"}
      informations << icon_tag('group_go') + link_to('【このグループへ参加申込みをする】', url_param, {:class => "nyroModal"})
    end

    if group.has_waiting and participation and participation.owned?
      informations << icon_tag('bell') + "承認待ちのメンバーがいます。"
    end
    informations
  end

  # 管理メニューの生成
  def get_manage_menu_items selected_menu
    @@menus = [{:name => "グループ情報変更", :menu => "manage_info" },
               {:name => "参加者管理",       :menu => "manage_participations"} ]
    @@menus << {:name => "参加者の承認",     :menu => "manage_permit" } if @group.protected?

    get_menu_items @@menus, selected_menu, "manage"
  end

  def get_select_user_options owners
    options_hash = {}
    owners.each { |owner| options_hash.store(owner.name, owner.id) }
    options_hash
  end

end
