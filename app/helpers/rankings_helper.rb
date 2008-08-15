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

module RankingsHelper
  def ranking_caption contents_type
    case contents_type
    when :entry_access
      "アクセス数が非常に多かったみんなが注目しているブログランキングです。"
    when :entry_comment
      "活発に意見が交わされたブログランキングです。グループの掲示板は対象外です。"
    when :entry_he
      "たくさん#{Admin::Setting.point_button}を押されたエントリのランキングです。グループの掲示板への投稿も含みます。"
    when :user_entry
      "個人のブログ投稿数ランキングです。(秘密日記込)"
    when :user_access
      "マイページに訪れた人の統計ランキングです。"
    else
      ""
    end
  end

  def ranking_title contents_type
    case contents_type
    when :entry_access
      "アクセス"
    when :entry_comment
      "コメント"
    when :entry_he
      "#{Admin::Setting.point_button!}"
    when :user_entry
      "投稿"
    when :user_access
      "訪問者"
    else
      ""
    end
  end
end
