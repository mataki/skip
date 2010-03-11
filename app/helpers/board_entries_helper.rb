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

module BoardEntriesHelper

  # ネスト構造のコメントを生成する
  def render_nest_comment comment, level, checked_on
    result = ""
    comment.children.each do |child_comment|
      result << render(:partial => "board_entry_comments/board_entry_comment", :locals => { :comment => child_comment, :level => level, :checked_on => checked_on })
    end
    result
  end

  def link_to_write_place owner
    return unless owner
    name = write_place_name(owner)
    unless name.blank?
      link_to name, [current_tenant, owner, :board_entries]
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
      link_to h(tag), tenant_board_entries_path(current_tenant, :tag_words => h(tag)), :class => 'tag'
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

  def send_mail_check_box_tag
    if SkipEmbedded::InitialSettings['mail']['show_mail_function']
      result = ''
      result << check_box(:board_entry, :send_mail)
      result << label(:board_entry, :send_mail, _('Send email to accessible members'))
      content_tag :span, result, :class => 'send_mail_field'
    end
  end

  # ページへのリンク
  # TODO: リファクタ プロックをわたせるようにしてview_textオプションを無くした方がよいと思う mat_aki
  def entry_link_to board_entry, options = {}, html_options = {}
    output_text = ""
    output_text << icon_tag('page') if options[:image_on]

    if limit = options[:truncate]
      title = truncate(board_entry.title, :length => limit)
    else
      title = board_entry.title
    end
    output_text << (options[:view_text] ? sanitize_style_with_whitelist(options[:view_text]) : h(title))

    html_options[:title] ||= board_entry.title
    link_to output_text, [current_tenant, board_entry.owner, board_entry], {:class => 'entry'}.merge(html_options)
  end

  # FIXME リンク先のコメントアウト部分の書き換え
  def show_contents entry
    output = ""
    if entry.editor_mode == 'hiki'
      output_contents = hiki_parse(entry.contents, entry.owner)
      image_url_proc = proc { |file_name|
        file_link_url({:owner_symbol => entry.owner_id, :file_name => file_name}, :inline => true)
      }
      output_contents = parse_hiki_embed_syntax(output_contents, image_url_proc)
      output = "<div class='hiki_style'>#{output_contents}</div>"
    elsif entry.editor_mode == 'richtext'
      output = render_richtext(entry.contents, entry.owner_id)
    else
      output_contents = CGI::escapeHTML(entry.contents)
      output_contents.gsub!(/((https?|ftp):\/\/[0-9a-zA-Z,;:~&=@_'%?+\-\/\$.!*()]+)/){|url|
        "<a href=\"#{url}\" target=\"_blank\">#{url}<\/a>"
      }
      output = "<pre>#{parse_permalink(output_contents, entry.owner)}</pre>"
    end
    output
  end

  # [コメント(n)-ポイント(n)-話題(n)-アクセス(n)]の表示
  def get_entry_infos entry
    output = []
    output << n_("Comment(%s)", "Comments(%s)", entry.board_entry_comments_count) % h(entry.board_entry_comments_count.to_s) if entry.board_entry_comments_count > 0
    output << "#{h Admin::Setting.point_button}(#{h entry.state.point.to_s})" if entry.state.point > 0
    output << n_("Trackback(%s)", "Trackbacks(%s)", entry.entry_trackbacks_count) % h(entry.entry_trackbacks_count.to_s) if entry.entry_trackbacks_count > 0
    output << n_("Access(%s)", "Accesses(%s)", entry.state.access_count) % h(entry.state.access_count.to_s) if entry.state.access_count > 0
    output.size > 0 ? "#{output.join('-')}" : '&nbsp;'
  end
end
