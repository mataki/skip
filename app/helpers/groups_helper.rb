# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008  TIS Inc.
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
    output = ''
    if participation = group.group_participations.detect{|participation| participation.user_id == user_id }
      if participation.owned?
        if options[:simple]
          output << icon_tag('emoticon_happy') + '管理者'
        else
          output << icon_tag('emoticon_happy') + '（管理者権限があります）'
        end
      elsif participation.waiting?
        if options[:simple]
          output << icon_tag('hourglass') + '承認'
        else
          output << icon_tag('hourglass') + '（現在承認待ちです）'
        end
      else
        if options[:simple]
          output << icon_tag('emoticon_smile') + '参加者'
        else
          output << icon_tag('emoticon_smile') + '（現在参加中です）'
        end
      end
    end
    output
  end

end
