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

module BoardEntriesHelper

  # ネスト構造のコメントを生成する
  def render_nest_comment comment, level
    result = ""
    comment.children.each do |child_comment|
      result << render(:partial => "board_entries/board_entry_comment", :locals => { :comment => child_comment, :level => level })
    end
    result
  end

  # 記事を書いた人かどうか
  def writer? comment, user_id
    user_id == comment.user_id
  end

  # 記事を書いた人及びコメントを書いた人かどうか
  def comment_writer? comment, user_id
    writer?(comment, user_id) || (comment.board_entry.user_id == user_id)
  end

  def date_with_icon date
    formated_date = "[ #{date.strftime('%Y/%m/%d-%H:%M')} ]"
    if Time.now - date < 12.hour
      "#{formated_date} #{icon_tag :emoticon_happy, :alt => _('[12時間以内のコメント]'), :title => _('[12時間以内のコメント]')}"
    elsif Time.now - date < 24.hour
      "#{formated_date} #{icon_tag :emoticon_smile, :alt => _('[24時間以内のコメント]'), :title => _('[24時間以内のコメント]')}"
    else
      formated_date
    end
  end

  def link_to_write_place owner
    name = write_place_name(owner)
    unless name.blank?
      link_to name, write_place_url(owner)
    else
      ''
    end
  end

  def write_place_name owner
    if owner
      return _("%s's Blog") % owner.name if owner.class == User
      return _("BBS of %s") % owner.name if owner.class == Group
    end
    ''
  end

  def write_place_url owner
    if owner
      return url_for(:controller => 'user', :action => 'blog', :uid => owner.uid, :archive => 'all') if owner.class == User
      return url_for(:controller => 'group', :action => 'bbs', :gid => owner.gid) if owner.class == Group
    end
  end
end
