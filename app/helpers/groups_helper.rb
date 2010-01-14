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
end
