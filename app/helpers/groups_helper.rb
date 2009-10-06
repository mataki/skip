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
      icon_tag('group_error') + _('Unjoined')
    end
  end

  # グループの状態をまとめて表示（グループのサマリと検索詳細結果で利用）
  def show_group_status(group, user_id)
    output = "<p>#{icon_tag(group.category_icon_name.first) + h(group.category_icon_name.last)}<br/></p>"
    output << "<p>#{participation_state(group, user_id)}<br/></p>"
    output << "<p>"
    output << (icon_tag('lock') + _('Need approval of the Administrator.')) if group.protected?
    output << "<br/></p>"
    output
  end

  # グループに対してできるアクションを表示（グループ一覧で利用）
  def show_group_action(group, show_favorite = false)
    output = ""
    if show_favorite
      participation = group.group_participations.first
      elem_id = "group_participation_#{participation.id}"
      output << "<span id='#{elem_id}'>#{render :partial => "groups/favorite", :locals => { :gid => group.gid, :participation => participation }}</span>"
    end
    output
  end
end
