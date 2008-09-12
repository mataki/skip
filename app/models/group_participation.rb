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

class GroupParticipation < ActiveRecord::Base
  belongs_to :user
  belongs_to :group

  N_('GroupParticipation|Waiting|true')
  N_('GroupParticipation|Waiting|false')
  N_('GroupParticipation|Owned|true')
  N_('GroupParticipation|Owned|false')
  N_('GroupParticipation|Favorite|true')
  N_('GroupParticipation|Favorite|false')

  # memcache領域にグループの参加情報を載せているため
  # 追加・削除の際はmemcache領域を削除する。
  # このためGroupParticipationテーブルには、deleteメソッドなど
  # after_xxx がかからないメソッドは使わないように。
  def after_save
    MemcacheUtil.clear(user.code, :skip) unless INITIAL_SETTINGS['belong_info_apps'].blank?
  end

  def after_destroy
    MemcacheUtil.clear(user.code, :skip) unless INITIAL_SETTINGS['belong_info_apps'].blank?
  end

  def to_s
    return '[id:' + id.to_s + ', user_id:' + user_id.to_s + ', group_id:' + group_id.to_s + ']'
  end

  #ユーザを指定して、その人が所属するgidの配列を取得する
  def self.get_gid_array_by_user_id(user_id)
    find(:all,
         :conditions => [" waiting = 0 and user_id = ?", user_id],
         :include =>'group').map {|group_participation| "gid:#{group_participation.group.gid}" } || []
  end
end
