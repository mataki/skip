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
      html_options = (source[:html_options] || {}).dup
      html_options.merge!(:class => 'selected') if current_page?(source[:options])
      title = content_tag(:span, source[:label])
      output << content_tag(:li, link_to(title, source[:options], html_options))
    end
    content_tag :ul, output
  end

  # 指定の件数を超えた場合のページ遷移のナビゲージョンリンクを生成する
  # will_paginate用
  def will_paginate_link pages
    option = params.clone
    output = ""
    output << link_to(_('[Head]'), option.update({:page => 1})) if pages.previous_page
    output << link_to(_('[Prev]'), option.update({:page => pages.previous_page})) if pages.previous_page
    output << _("Total %{items} hits (Page %{page} / %{pages})") % {:items => pages.total_entries, :page => pages.current_page, :pages => pages.total_pages}
    output << link_to(_('[Next]'), option.update({:page => pages.next_page})) if pages.next_page
    output << link_to(_('[Last]'), option.update({:page => pages.total_pages})) if pages.next_page
    output
  end

  # 複数のラジオボタンで値を選択するHTMLを生成する
  def radio_buttons(object, method, choices, options = {})
    output = ""
    choices.each do |choice|
      output << radio_button(object, method, choice.last, options)
      output << label_tag("#{object}_#{method}_#{choice.last}", h(choice.first))
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
      title = truncate(board_entry.title, :length => limit)
    else
      title = board_entry.title
    end
    output_text << (sanitize(options[:view_text]) || h(title))

    html_options[:title] ||= board_entry.title
    link_to output_text, board_entry.get_url_hash, {:class => 'entry'}.merge(html_options)
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
    link_to show_picture(user, options), {:controller => '/user', :action => 'show', :uid => user.uid}, {:title => h(user.name)}
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

  def show_picture(user, options = {})
    options = {:border => '0', :name => 'picture', :alt => h(user.name), :popup => false, :fit_image => true}.merge(options)
    options.merge!(:class => 'fit_image') if options.delete(:fit_image)
    if user.retired?
      file_name = 'retired.png'
    elsif picture = user.picture
      unless picture.new_record?
        file_name = url_for(:controller => '/pictures', :action => 'picture', :id => picture.id, :format => :png)
        if options.delete(:popup)
          pop_name = url_for(:controller => '/pictures', :action => 'picture', :id => picture.id.to_s)
          options[:title] = _("Click to see in original size.")
          return link_to(image_tag(file_name, options), file_name, :class => 'nyroModal zoomable')
        end
      else
        file_name = 'default_picture.png'
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
    "<div class='rich_style ui-corner-all'>#{sanitize_and_unescape_for_richtext(content)}</div>"
  end

  def sanitize_and_unescape_for_richtext(content)
    content.gsub!(/(?:<|&lt;)!--.*?--(?:>|&gt;)/m, '') unless content.blank?
    sanitize_style_with_whitelist(BoardEntry.unescape_href(content))
  end

  def sanitize_style_with_whitelist(content)
    allowed_tags = HTML::WhiteListSanitizer.allowed_tags.dup << "table" << "tbody" << "tr" << "th" << "td" << "caption" << "strike" << "u"
    allowed_attributes = HTML::WhiteListSanitizer.allowed_attributes.dup << "style" << "cellspacing" << "cellpadding" << "border" << "align" << "summary"
    sanitize(content, :tags => allowed_tags, :attributes => allowed_attributes)
  end

  def get_publication_type_icon(entry)
    icon_name = ''
    view_name = ""
    case entry.publication_type
    when 'public'
      icon_name = 'page_red'
      view_name = _("Open to All")
    when 'protected'
      visibility, visibility_color = entry.visibility
      icon_name = 'page_link'
      view_name = _("Specified Directly:") + visibility
    when 'private'
      icon_name = 'page_key'
      view_name = entry.diary? ? _("Owner Only") : _("Members Only")
   end
    icon_tag(icon_name, :title => view_name)
  end

  # [コメント(n)-ポイント(n)-話題(n)-アクセス(n)]の表示
  def get_entry_infos entry
    output = []
    output << n_("Comment(%s)", "Comments(%s)", entry.board_entry_comments_count) % h(entry.board_entry_comments_count.to_s) if entry.board_entry_comments_count > 0
    output << "#{h Admin::Setting.point_button}(#{h entry.point.to_s})" if entry.point > 0
    output << n_("Trackback(%s)", "Trackbacks(%s)", entry.entry_trackbacks_count) % h(entry.entry_trackbacks_count.to_s) if entry.entry_trackbacks_count > 0
    output << n_("Access(%s)", "Accesses(%s)", entry.state.access_count) % h(entry.state.access_count.to_s) if entry.state.access_count > 0
    output.size > 0 ? "[#{output.join('-')}]" : ""
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
  # TODO 単なるTagの配列じゃ駄目で、(:select 'count(tags.id) as count')などとしておかないといけない。呼び出し元で気をつけて配列を作らないといけない部分が微妙。なんとかしたい。
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
    unless application_links.empty?
      application_links.unshift(link_to(Admin::Setting.abbr_app_title, root_url, :class => "underline_link"))
      application_link = content_tag :div, :id => 'collaboration_apps_link' do
        application_links.join('&nbsp')
      end
      application_link
    end
  end

  def footer_link
    returning str = "" do |s|
      s << content_tag(:div, :class => "info") do
        content_tag(:div, Admin::Setting.footer_first, :class => "first") +
          content_tag(:div, Admin::Setting.footer_second, :class => "second")
      end
      if footer_image_link_tag = SkipEmbedded::InitialSettings['footer_image_link_tag']
        s << content_tag(:div, footer_image_link_tag, :class => "powered_by")
      else
        s << content_tag(:div, ("powered_by"+link_to(image_tag(root_url + "custom/images/footer_logo.png"), h(Admin::Setting.footer_image_link_url))), :class => "powered_by")
      end
    end
  end

  def shortcut_menus
    return if !current_user || current_user.groups.participating(current_user).empty?
    option_tags = [content_tag(:option, _('Move to groups joined ...'), :value => url_for({:controller => '/mypage', :action => 'group'}))]

    GroupCategory.all.each do |category|
      if groups = category.groups.participating(current_user).order_participate_recent and !groups.empty?
        option_tags << content_tag(:option, "[#{h(category.name)}]", :disabled => 'disabled', :style => 'color: gray')
        groups.each do |group|
          option_tags << content_tag(:option, "&nbsp;#{truncate(h(group.name), 15)}", :value => url_for({:controller => '/group', :gid => group.gid, :action => 'show'}))
        end
      end
    end
    "<select class=\"select_navi\">#{option_tags.join('')}</select>"
  end

  def global_links
    links = ''
    links << content_tag(:span, link_to_unless_current(icon_tag('house', :title => _('My Page')) + _('My Page'), root_url), :class => 'home_link')
    other_links = []
    links << content_tag(:span, other_links, :class => 'other_links')
    search_links = []
    search_links << link_to_unless_current(icon_tag('report', :title => _('Entries')) + _('Entries'),  :controller => '/search', :action => 'entry_search') if BoardEntry.count > 0
    search_links << link_to_unless_current(icon_tag('disk_multiple', :title => _('Files')) + _('Files'),  :controller => '/search', :action => 'share_file_search') if ShareFile.count > 0
    search_links << link_to_unless_current(icon_tag('user_suit', :title => _('Users')) + _('Users'),  :controller => '/users', :action => 'index') if User.count > 1
    search_links << link_to_unless_current(icon_tag('group', :title => _('Groups')) + _('Groups'),  :controller => '/groups', :action => 'index') if Group.count > 0
    search_links << link_to_unless_current(icon_tag('tag_blue', :title => _('Bookmarks')) + _('Bookmarks'),  :controller => '/bookmarks', :action => 'index') if Bookmark.count > 0
    links << content_tag(:span, search_links.join(' '), :class => 'search_links')
  end

private
  def relative_url_root
    ActionController::Base.relative_url_root || ''
  end

  # TODO 仕組みが複雑すぎる。BoardEntry.replace_symbol_linkと合わせてシンプルな作りにしたい。
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
                      file_name.gsub!(/\r\n|\r|\n/, '')
                      url = share_file_url :controller_name => @@CONTROLLER_HASH[symbol_type], :symbol_id => symbol_id, :file_name => file_name.strip, :authenticity_token => form_authenticity_token
                      link_to(link_str, url) }

    procs = [["uid", default_proc], ["gid", default_proc], ["page", default_proc]]
    procs << ["file",file_proc] if owner_symbol

    split_mark =  "&gt;"
    procs.each { |value| text = BoardEntry.replace_symbol_link(text, value.first, value.last, split_mark) }
    return text
  end

  def link_to_bookmark_url(bookmark, title = nil)
    title ||= bookmark.title

    if bookmark.is_type_page?
      link_to "#{icon_tag('report_link')} #{h title}", "#{relative_url_root}#{bookmark.escaped_url}", :title => title
    else
      link_to "#{icon_tag('world_link')} #{h truncate(title, :length => 115)}", bookmark.escaped_url, :title => title, :target => "_blank"
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
    output = "<span>#{categories.slice!(0..visible_size-1)}"
    if categories.size > 0
      output << "<a href='#' class='tag_open'>#{icon_tag 'bullet_toggle_plus'}</a>"
      output << "<span style='display: none;'>#{categories}"
      output << "<a href='#' class='tag_close'>#{icon_tag 'bullet_toggle_minus'}</a>"
      output << "</span>"
    end
    output << "</span>"
  end
end
