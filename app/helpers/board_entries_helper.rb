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

module BoardEntriesHelper

  # ネスト構造のコメントを生成する
  def render_nest_comment comment, level, checked_on
    result = ""
    comment.children.each do |child_comment|
      result << render(:partial => "board_entries/board_entry_comment", :locals => { :comment => child_comment, :level => level, :checked_on => checked_on })
    end
    result
  end

  # 記事を書いた人かどうか
  # TODO BoardEntry#writer?と重複してる。無くしたい
  def writer? comment, user_id
    user_id == comment.user_id
  end

  # 記事を書いた人及びコメントを書いた人かどうか
  # TODO BoardEntryComment#writer?となるようにしたい。
  def comment_writer? comment, user_id
    writer?(comment, user_id) || (comment.board_entry.user_id == user_id)
  end

  def link_to_write_place owner
    name = write_place_name(owner)
    unless name.blank?
      link_to name, write_place_url(owner)
    else
      ''
    end
  end

  # edit_controllerからも呼ばれているため、ERBクラスを指定してサニタイズする
  def write_place_name owner
    if owner
      return _("%s's Blog") % ERB::Util.html_escape(owner.name) if owner.class == User
      return _("Forums of %s") % ERB::Util.html_escape(owner.name) if owner.class == Group
    end
    ''
  end

  def write_place_url owner
    if owner
      return url_for(:controller => 'user', :action => 'blog', :uid => owner.uid, :archive => 'all') if owner.class == User
      return url_for(:controller => 'group', :action => 'bbs', :gid => owner.gid) if owner.class == Group
    end
  end

  def comment_title_class current_user, comment, checked_on
    if current_user.id == comment.user_id
      'title current_user'
    elsif checked_on && checked_on <= comment.updated_on
      'title other_user not_read'
    else
      'title other_user read'
    end
  end

  def icon_with_information current_user, comment, checked_on
    text = ''
    text << _('[New]') if Time.now - comment.created_on < 24.hour
    text << _('[Unread]') if current_user.id != comment.user_id && (checked_on.blank? || checked_on <= comment.updated_on)
    icon_type = Time.now - comment.created_on < 12.hour ? :emoticon_happy : :emoticon_smile
    text.blank? ? "" : "#{icon_tag icon_type}#{text}"
  end

  # :maxを指定すると指定サイズを超えるタグを隠す。開閉するためにはapplication.jsを読み込んでおかなければならない。
  def entry_tag_search_links_tag comma_tags, options = {}
    return '' if comma_tags.blank?
    tag_links = comma_tags.split(',').map do |tag|
      link_to h(tag), {:controller => 'search', :action => 'entry_search', :tag_words => h(tag)}, :class => 'tag'
    end
    if max = options[:max] and max > 0
      toggle_links(tag_links, max)
    else
      tag_links.join(',&nbsp;')
    end
  end

  def detect_entry_gb_class entry
    if entry.protected?
      'all_protected'
    elsif entry.entry_type == 'DIARY'
      case
      when entry.public? then 'blog_public'
      when entry.private? then 'blog_private'
      end
    elsif entry.entry_type == 'GROUP_BBS'
      case
      when entry.public? then 'forum_public'
      when entry.private? then 'forum_private'
      end
    end
  end

  def parse_hiki_embed_syntax view_str, proc
    regex_type = /\{\{.+?\}\}/ # {{***}}とマッチする正規表現
    width = 0
    height = 0
    image_name = ""

    while image_tag = view_str.match(regex_type)
      image_size = [0,0] # デフォルトサイズ

      # カンマ２つでサイズが指定してある場合
      if image_tag.to_s.scan(",").size == 2
        params = image_tag.to_s[2..-3].split(",")
        image_name = params[0]
        width, height = [params[1].to_i, params[2].to_i]
      else
        image_name = image_tag.to_s[2..-3]
      end
      image_name.strip!

      #イメージのURLを生成できるブロックを呼び出す
      image_url = proc.call(image_name)
      image_link =
        if File.extname(image_name).sub(/\A\./,'').downcase == "flv"
          flv_tag image_url
        elsif File.extname(image_name).sub(/\A\./,'').downcase == "swf"
          width = 240 if width == 0
          height = (width * 0.75) if height == 0
          swf_tag image_url, :width => width, :height => height
        else
          img_options = {}
          img_options[:width] = width if width > 0
          img_options[:height] = height if height > 0
          link_to image_tag(image_url, img_options), image_url, :class => 'zoomable'
        end

      view_str = view_str.sub(regex_type, image_link)
    end
    return view_str
  end

end
