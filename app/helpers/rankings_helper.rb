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
  def ranking_title contents_type
    case contents_type
    when :entry_access
      "人気ブログランキング(アクセス）"
    when :entry_comment
      "人気ブログランキング(コメント）"
    when :entry_he
      "人気ブログランキング(#{Admin::Setting.point_button})"
    when :user_access
      "人気ユーザランキング"
    when :user_entry
      "ブログ投稿数ランキング"
    when :commentator
      "コメント投稿数ランキング"
    else
      ""
    end
  end
  
  def ranking_caption contents_type
    case contents_type
    when :entry_access
      "みんなによく読まれたブログ/掲示板です(公開範囲が「全公開」のみ)"
    when :entry_comment
      "みんなからコメントが活発に付いたブログです(公開範囲が「全公開」のみ)"
    when :entry_he
      "みんなから最も#{Admin::Setting.point_button}を貰ったブログ/掲示板です(公開範囲が「全公開」のみ)"
    when :user_access
      "みんなから書いたブログや自身のプロフィールによく訪れてもらったユーザです"
    when :user_entry
      "最もブログを投稿したユーザです(公開範囲に関わらず、カウント)"
    when :commentator
      "最もコメントを付けたユーザです(公開範囲に関わらず、カウント)"
    else
      ""
    end
  end

  def ranking_amount_name contents_type
    case contents_type
    when :entry_access
      "アクセス数"
    when :entry_comment
      "コメント件数"
    when :entry_he
      "#{Admin::Setting.point_button}"
    when :user_access
      "アクセス数"
    when :user_entry
      "ブログ件数"
    when :commentator
      "コメント件数"
    else
      ""
    end
  end

  def show_title_col? contents_type
    ranking_data_type(contents_type).to_s == "entry"
  end

  def ranking_data_type contents_type
    case contents_type
    when :entry_access 
      "entry"
    when :entry_comment 
      "entry"
    when :entry_he
      "entry"
    when :user_access
      "user"
    when :user_entry
      "user"
    when  :commentator
      "user"
    else
      ""
    end
  end

end
