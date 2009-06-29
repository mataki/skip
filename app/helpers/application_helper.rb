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

module ApplicationHelper
  include InitialSettingsHelper
  include CacheHelper
  include SkipHelper
  include HelpIconHelper

  @@CONTROLLER_HASH = { 'uid'  => 'user',
                        'gid'  => 'group',
                        'page' => 'page'}

  # レイアウトのタブメニューを生成する
  def generate_tab_menu(tab_menu_sources)
    output = ''
    tab_menu_sources.each do |source|
      html_options = source[:html_options] || {}
      if controller.action_name == source[:options][:action] || (source[:selected_actions] && source[:selected_actions].include?(controller.action_name))
        html_options.merge!(:class => 'selected')
      end
      title =  content_tag(:span, source[:label])
      output << content_tag(:li, link_to(title, source[:options], html_options))
    end
    content_tag :ul, output
  end

  # 指定の件数を超えた場合のページ遷移のナビゲージョンリンクを生成する
  def page_link pages
    option = params.clone
    output = ""
    output << link_to(_('[Head]'), option.update({:page => 1})) if pages.current.previous
    output << link_to(_('[Prev]'), option.update({:page => pages.current.previous})) if pages.current.previous
    output << _("Total %{items} hits (Page %{page} / %{pages})") % {:items => pages.item_count, :page => pages.current.number, :pages =>pages.length}
    output << link_to(_('[Next]'), option.update({:page => pages.current.next})) if pages.current.next
    output << link_to(_('[Last]'), option.update({:page => pages.last})) if pages.current.next
    output
  end

  # 複数のラジオボタンで値を選択するHTMLを生成する
  def radio_buttons(object, method, choices, options = {})
    output = ""
    choices.each do |choice|
      output << radio_button(object, method, choice.last, options)
      output << choice.first
    end
    output
  end

  # spanタグによる擬似リンクを生成する
  def dummy_link_to name, options = { }
    options.store(:onmouseover, "this.style.color='blue';this.style.textDecoration='underline';")
    options.store(:onmouseout,  "this.style.color='#0080ff';this.style.textDecoration='none';")
    options.store(:style, "cursor: pointer;color: #0080ff;");
    options.store(:tabindex, "0");
    output = tag("span", options, true)
    output << name
    output << "</span>"
  end

  # ページへのリンク
  # TODO: リファクタ プロックをわたせるようにしてview_textオプションを無くした方がよいと思う mat_aki
  def entry_link_to board_entry, options = {}, html_options = {}
    output_text = ""
    output_text << icon_tag('page') if options[:image_on]

    if limit = options[:truncate]
      title = truncate(board_entry.title, limit)
    else
      title = board_entry.title
    end
    output_text << (sanitize(options[:view_text]) || h(title))

    html_options[:title] ||= board_entry.title
    link_to output_text, board_entry.get_url_hash, html_options
  end

  # ユーザのページへのリンク
  def user_link_to user, options = {}
    output_text = ""
    output_text << icon_tag('user_suit') if options[:image_on]
    output_text << title = h(user.name)

    link_to output_text, {:controller => 'user', :action => 'show', :uid => user.uid}, {:title => title}
  end

  def user_link_to_with_portrait user, options = {}
    options = {:width => 120, :height => 80}.merge(options)
    link_to showPicture(user, options[:width], options[:height]), {:controller => 'user', :action => 'show', :uid => user.uid}, {:title => h(user.name)}
  end

  # グループのページへのリンク
  def group_link_to group, options = {}
    output_text = ""
    output_text << icon_tag('group.png') if options[:image_on]
    output_text << (options[:view_text] || h(group.name))

    link_to output_text, { :controller => 'group', :action => 'show', :gid => group.gid }, options
  end

  # ユーザかグループのページへのリンク
  def item_link_to item, options = {}
    output_text = ""
    output_text << image_tag(option[:image_name]) if options[:image_name]
    output_text << (options[:view_text] || h(item[:name]))

    url = { :controller => item.class.name.downcase,
            :action => 'show',
            item.class.symbol_type => item.symbol_id }

    link_to output_text, url, { :title => h(item[:name]) }
  end

  def symbol_link_to symbol, name = nil
    symbol_type, symbol_id = SkipUtil.split_symbol symbol
    name ||= "[#{symbol}]"
    link_to(h(name), {:controller => @@CONTROLLER_HASH[symbol_type], :action => "show", symbol_type => symbol_id}, :title => name)
  end

  def image_link_tag title, image_name, options={}
    link_to image_tag(image_name, :alt => title) + title, options
  end

  def showPicture(user, width, height, popup = false)
    options = {:border => '0', :name => 'picture', :alt => h(user.name)}
    options[:width] = width unless width == 0
    options[:height] = height unless height == 0
    if user.retired?
      file_name = 'retired.png'
    elsif picture = user.pictures.first
      file_name = url_for(:controller => 'pictures', :action => 'picture', :id => picture.id, :format => :png)
      if popup
        pop_name = url_for(:controller => 'pictures', :action => 'picture', :id => picture.id.to_s)
        options[:title] = _("Click to see in original size.")
        return link_to(image_tag(file_name, options), file_name, :class => 'nyroModal zoomable')
      end
    else
      file_name = 'default_picture.png'
    end
    image_tag(file_name, options)
  end

  def show_contents entry
    output = ""
    if entry.editor_mode == 'hiki'
      output_contents = hiki_parse(entry.contents, entry.symbol)
      image_url_proc = proc { |file_name|
        file_link_url :owner_symbol => entry.symbol, :file_name => file_name
      }
      output_contents = SkipUtil.images_parse(output_contents, image_url_proc)
      output = "<div class='hiki_style'>#{output_contents}</div>"
    elsif entry.editor_mode == 'richtext'
      output = render_richtext(entry.contents, entry.symbol)
    else
      output_contents = CGI::escapeHTML(entry.contents)
      output_contents.gsub!(/((https?|ftp):\/\/[0-9a-zA-Z,;:~&=@_'%?+\-\/\$.!*()]+)/){|url|
        "<a href=\"#{url}\" target=\"_blank\">#{url}<\/a>"
      }
      output = "<pre>#{parse_permalink(output_contents, entry.symbol)}</pre>"
    end
    output
  end

  # ファイルダウンロードへのリンク
  def file_link_to share_file, options = {}, html_options = {}
    file_name = options[:truncate] ? truncate(share_file.file_name, options[:truncate]) : share_file.file_name
    url = file_link_url(share_file)
    link_to h(file_name), url, html_options
  end

  def file_link_url share_file
    share_file = ShareFile.new share_file if share_file.is_a? Hash
    symbol_type, symbol_id = SkipUtil.split_symbol share_file.owner_symbol
    url_params = {:controller_name => share_file.owner_symbol_type,
                  :symbol_id => symbol_id,
                  :file_name => share_file.file_name}
    url = share_file_url(url_params)
    url
  end

  def hiki_parse text, owner_symbol = nil
    text = HikiDoc.new((text || ''), Regexp.new(SkipEmbedded::InitialSettings['not_blank_link_re'])).to_html
    parse_permalink(text, owner_symbol)
  end

  # リッチテキストの表示
  def render_richtext(text, owner_symbol = nil)
    content = parse_permalink(text, owner_symbol)
    "<div class='rich_style'>#{sanitize_style_with_whitelist(content)}</div>"
  end

  def sanitize_style_with_whitelist(content)
    allowed_tags = HTML::WhiteListSanitizer.allowed_tags.dup << "table" << "tbody" << "tr" << "th" << "td" << "caption" << "strike" << "u"
    allowed_attributes = HTML::WhiteListSanitizer.allowed_attributes.dup << "style" << "cellspacing" << "cellpadding" << "border" << "align" << "summary"
    sanitize(content, :tags => allowed_tags, :attributes => allowed_attributes)
  end

  # ホームのあなたへの連絡、みんなへの連絡の重要マークをつける
  def get_light_icon(entry)
    entry.important? ? icon_tag('lightbulb') : ''
  end

  def get_publication_type_icon(entry)
    icon_name = ''
    view_name = ""
    case entry.publication_type
    when 'public'
      icon_name = 'page_red'
      view_name = "全体に公開"
    when 'protected'
      visibility, visibility_color = entry.visibility
      icon_name = 'page_link'
      view_name = "直接指定:" + visibility
    when 'private'
      icon_name = 'page_key'
      view_name = entry.diary? ? "自分だけ" : "参加者のみ"
   end
    icon_tag(icon_name, :title => view_name)
  end

  # [コメント(n)-ポイント(n)-話題(n)-アクセス(n)]の表示
  def get_entry_infos entry
    output = ""
    output << n_("Comment(%s)", "Comments(%s)", entry.board_entry_comments_count) % h(entry.board_entry_comments_count.to_s) if entry.board_entry_comments_count > 0
    output << "#{h Admin::Setting.point_button}(#{h entry.point.to_s})" if entry.point > 0
    output << n_("Trackback(%s)", "Trackbacks(%s)", entry.entry_trackbacks_count) % h(entry.entry_trackbacks_count.to_s) if entry.entry_trackbacks_count > 0
    output << n_("Access(%s)", "Accesses(%s)", entry.state.access_count) % h(entry.state.access_count.to_s) if entry.state.access_count > 0
    output = "[#{output}]" if output.size > 0
    return output
  end

  def get_menu_items menus, selected_menu, action
    menu_items = []
    menus.each do |menu|
      if menu[:menu] == selected_menu
        menu_items << icon_tag('bullet_red') + "<b>#{menu[:name]}</b>"
      else
        link_to_params = { :action => action, :menu => menu[:menu] }
        menu_items << icon_tag('bullet_blue') + link_to(menu[:name], link_to_params, :confirm => menu[:confirm])
      end
    end
    menu_items
  end

  # タグクラウドを生成する
  def tag_cloud(tags, classes = %w(tag1 tag2 tag3 tag4 tag5 tag6))
    max, min = 0, 0
    tags.each do |tag|
      max = tag.count.to_i if tag.count.to_i > max
      min = tag.count.to_i if tag.count.to_i < min
    end
    divisor = ((max - min) / classes.size) + 1
    tags.each do |tag|
      yield tag.name, tag.count, classes[(tag.count.to_i - min) / divisor]
    end
  end

  def get_group_icon(category, options = {:margin => false})
    options[:alt] = category.code
    icon_tag(category.icon, options)
  end

  def url_for_bookmark bookmark
    url_for :controller => 'bookmark', :action => 'show', :uri => bookmark.escaped_url
  end

  def header_logo_link(url = url_for(:controller => '/mypage', :action => 'index'))
    img_url = url_for("#{root_url}/custom/images/header_logo.png")
    "<div id=\"logo\">" + link_to(image_tag(img_url, :alt => h(Admin::Setting.abbr_app_title), :height => "45"), url) + "</div>"
  end

  def favicon_include_tag
    favicon_url = url_for(relative_url_root + "/custom/favicon.ico")
    %!<link rel="shortcut icon" href="#{favicon_url}" />! +
      %!<link rel="icon" href="#{favicon_url}" type="image/ico" />!
  end

  def application_link
    application_links = OauthProvider.enable.map do |p|
      link_to(h(p.setting.name), h(p.setting.root_url), :class => "underline_link")
    end
    other_links = []
    unless COMMON_MENUS.empty?
      application_links << link_to( content_tag('u',_('more')) + content_tag('small', "▼"), '#', :id => 'other_link')
      COMMON_MENUS[:menus].each do |menu|
        if menu[:url]
          other_links << link_to(h(menu[:title]), menu[:url], :target => '_blank')
        else
          other_links << content_tag(:p, h(menu[:title]))
          menu[:links].each do |link|
            other_links << link_to(h(link[:title]), link[:url], :target => '_blank')
          end
        end
      end
    end
    unless application_links.empty?
      application_links.unshift(link_to(Admin::Setting.abbr_app_title, root_url, :class => "underline_link"))
      application_link = content_tag :div, :id => 'collaboration_apps_link' do
        application_links.join('&nbsp')
      end
      other_links_tag = content_tag :div, :id => 'other_links', :class => 'invisible' do
        other_links.join('')
      end
      "#{application_link}#{other_links_tag}"
    end
  end

  def shortcut_menus
    menus =  []
    menus << link_to(icon_tag(:report_edit, :title => 'ブログを書く') + 'ブログを書く', :controller => '/edit', :action => :index)

    option_tags = []
    option_tags << content_tag(:option, _('参加グループへ移動 ... '), :value => url_for({:controller => '/mypage', :action => 'group'}))
    option_tags << content_tag(:option, '----', :value => '----')

    Group.favorites_per_category(current_user).each do |category|
      option_tags << content_tag(:option, "[#{h(category[:name])}]", :disabled => 'disabled', :style => 'color: gray')
      category[:groups].each do |group|
        option_tags << content_tag(:option, "&nbsp;#{h(group.name)}", :value => url_for({:controller => '/group', :gid => group.gid, :action => 'show'}))
      end
    end

    option_tags << content_tag(:option, '----', :value => '----')
    option_tags << content_tag(:option, _('参加グループ'), :value => url_for({:controller => '/mypage', :action => 'group'}))

    menus << "#{icon_tag(:group_go, :title => _('マイグループ'))}<select class=\"select_navi\">#{option_tags.join('')}</select>"
    menus
  end

private
  def relative_url_root
    ActionController::AbstractRequest.relative_url_root
  end

  def parse_permalink text, owner_symbol = nil
    return '' unless text
    # closure
    default_proc = proc { |symbol, link_str|
                          symbol_type, symbol_id = SkipUtil.split_symbol symbol
                          url = url_for("#{relative_url_root}/#{@@CONTROLLER_HASH[symbol_type]}/#{symbol_id.strip}/")
                          link_to(link_str, url) }
    # closure
    file_proc = proc {|file_symbol, link_str|
                      symbol_type, symbol_id = SkipUtil.split_symbol owner_symbol
                      f_symbol_type, file_name = SkipUtil.split_symbol file_symbol
                      url = share_file_url :controller_name => @@CONTROLLER_HASH[symbol_type], :symbol_id => symbol_id, :file_name => file_name.strip, :authenticity_token => form_authenticity_token
                      link_to(link_str, url) }

    procs = [["uid", default_proc], ["gid", default_proc], ["page", default_proc]]
    procs << ["file",file_proc] if owner_symbol

    split_mark =  "&gt;"
    procs.each { |value| text = BoardEntry.replace_symbol_link(text, value.first, value.last, split_mark) }
    return text
  end

  def link_to_bookmark_url(bookmark, title = nil)
    url = bookmark.url
    title ||= bookmark.title

    if bookmark.is_type_page?
      url =  relative_url_root + url
      link_to "#{icon_tag('report_link')} #{h title}", bookmark.escaped_url, :title => title
    elsif bookmark.is_type_user?
      url =  relative_url_root + url
      link_to "#{icon_tag('user')} #{h title}", bookmark.escaped_url, :title => title
    else
      link_to "#{icon_tag('world_link')} #{h truncate(title, 115)}", bookmark.escaped_url, :title => title
    end
  end

  # 検索条件に使うプルダウン表示用
  def selected_tag (name, selected_value, choices, options={})
    output =" <select id='#{name}' name='#{name}'>"
    output << "<option value=''></option>" if options[:include_blank]
    for choice in choices
      output << "<option value='#{choice.last}' "
      output << "selected" if selected_value == choice.last
      output << ">#{choice.first}</option>"
     end
   return  output << "</select>"
  end

  # javascriptで長いタグを収納する application.jsを読み込む必要あり
  # visible_size で 初期表示のタグの個数を指定できる。
  def hide_long_tags(categories, visible_size = 1)
    output = "<span style='font-size:10px; color: #8080ff;'>#{categories.slice!(0..visible_size-1)}"
    if categories.size > 0
      output << "<a href='#' class='tag_open'>#{icon_tag 'bullet_toggle_plus'}</a>"
      output << "<span style='display: none;'>#{categories}"
      output << "<a href='#' class='tag_close'>#{icon_tag 'bullet_toggle_minus'}</a>"
      output << "</span>"
    end
    output << "</span>"
  end
end
