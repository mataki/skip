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

module ApplicationHelper
  include InitialSettingsHelper
  include CacheHelper
  include SkipHelper
  @@CONTROLLER_HASH = { 'uid'  => 'user',
                        'gid'  => 'group',
                        'page' => 'page'}

  # レイアウトのタブメニューを生成する
  # menu_source:: メニュー名とアクションを配列にした項目の配列 ex.[ [name, action] ]
  # option:: リンクにつけるオプションのHash（デフォルト空）
  def generate_tab_menu menu_source, option = {}
    menu_source ||= []
    option ||= {}

    output = ''
    menu_source.each do |menu|
      output << generate_tab_link(menu.first, option.merge({ :action=>menu.last }))
    end
    '<ul>' + output + '</ul>'
  end

  # 指定の件数を超えた場合のページ遷移のナビゲージョンリンクを生成する
  def page_link pages
    option = params.clone
    output = ""
    output << link_to('[Head]', option.update({:page => 1})) if pages.current.previous
    output << link_to('[Prev]', option.update({:page => pages.current.previous})) if pages.current.previous
    output << %(全#{pages.item_count}件（#{pages.current.number}/#{pages.length}ページ）)
    output << link_to('[Next]', option.update({:page => pages.current.next})) if pages.current.next
    output << link_to('[Last]', option.update({:page => pages.last})) if pages.current.next
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
  def entry_link_to board_entry, options = {}, html_options = {}
    output_text = ""
    output_text << icon_tag('page') if options[:image_on]

    if limit = options[:truncate]
      title = truncate(board_entry.title, limit)
    else
      title = board_entry.title
    end
    output_text << (options[:view_text] || title)

    html_options[:title] ||= board_entry.title
    output_text = h(output_text) unless output_text.include?('<img')
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

    link_to output_text, { :controller=>'group', :action=>'show', :gid=>group.gid }, options
  end

  # ユーザかグループのページへのリンク
  def item_link_to item, options = {}
    output_text = ""
    output_text << image_tag(option[:image_name]) if options[:image_name]
    output_text << (options[:view_text] || h(item[:name]))

    url = { :controller=>item.class.name.downcase,
            :action=>'show',
            item.class.symbol_type=>item.symbol_id }

    link_to output_text, url, { :title => h(item[:name]) }
  end

  def symbol_link_to symbol, name = nil
    symbol_type, symbol_id = SkipUtil.split_symbol symbol
    name ||= "[#{symbol}]"
    link_to(h(name), {:controller => @@CONTROLLER_HASH[symbol_type], :action => "show", symbol_type => symbol_id}, :title => name)
  end

  # ファイルダウンロードへのリンク
  def file_link_to share_file, html_options = {}
    url = file_link_url(share_file)
    link_to h(share_file.file_name), url, html_options
  end

  def file_link_url share_file
    symbol_type, symbol_id = SkipUtil.split_symbol share_file.owner_symbol
    url_params = {:controller_name => @@CONTROLLER_HASH[symbol_type],
                  :symbol_id => symbol_id,
                  :file_name => share_file.file_name}
    url = share_file_url(url_params)
    url
  end

  def image_link_tag title, image_name, options={}
    link_to image_tag(image_name, :alt=>title) + title, options
  end

  def showPicture(user, width, height, popup = false)
    options = {:border=>'0', :name=>'picture', :alt=>user.name}
    options[:width] = width unless width == 0
    options[:height] = height unless height == 0
    if user.retired?
      file_name = 'retired.png'
    elsif picture = user.pictures.first
      file_name = '/pictures/picture/' + picture.id.to_s + '.png'
      if popup
        pop_name = url_for(:controller => 'pictures', :action => 'picture', :id => picture.id.to_s)
        options[:title] = "クリックすると実際の大きさで表示されます"
        return link_to(image_tag(file_name, options), file_name, :class => 'nyroModal zoomable')
      end
    else
      file_name = 'default_picture.png'
    end
    image_tag(file_name, options)
  end

  def hiki_parse text, owner_symbol = nil
    text ||= ''
    parse_permalink(HikiDoc.new(text, Regexp.new(INITIAL_SETTINGS['not_blank_link_re'])).to_html, owner_symbol)
  end

  def show_contents entry
    output = ""
    if entry.editor_mode == 'hiki'
      output_contents = hiki_parse(entry.contents, entry.symbol)
      board_entry_image_url_proc = proc { |file_name|
        entry.image_url(file_name)
      }
      output_contents = SkipUtil.images_parse(output_contents, board_entry_image_url_proc)
      output = '<div class="hiki_style">'
      output << output_contents
      output << '</div>'
    elsif entry.editor_mode == 'richtext'
      output = '<div class="rich_style">'
      output << parse_permalink(entry.contents, entry.symbol);
      output << '</div>'
    else
      output_contents = CGI::escapeHTML(entry.contents)
      output_contents.gsub!(/((https?|ftp):\/\/[0-9a-zA-Z,;:~&=@_'%?+\-\/\$.!*()]+)/){|url|
        "<a href=\"#{url}\" target=\"_blank\">#{url}<\/a>"
      }
      output_contents = parse_permalink(output_contents, entry.symbol);
      output = '<pre>'
      output << output_contents
      output << '</pre>'
    end
    output
  end

  #ホームのあなたへの連絡、みんなへの連絡の重要マークをつける
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
    icon_tag(icon_name, :alt => view_name, :title => view_name)
  end

  # [コメント(n)-ポイント(n)-話題(n)-アクセス(n)]の表示
  def get_entry_infos entry
    output = "[コメント(#{entry.board_entry_comments_count})"
    output << "-#{h Admin::Setting.point_button}(#{h entry.point.to_s})"
    output << "-話題(#{h entry.entry_trackbacks_count})"
    output << "-アクセス(#{h entry.state.access_count.to_s})]"
    return output
  end

  def get_menu_items menus, selected_menu, action
    menu_items = []
    menus.each do |menu|
      if menu[:menu] == selected_menu
        menu_items << icon_tag('bullet_red') + "<b>#{menu[:name]}</b>"
      else
        link_to_params = { :action=>action, :menu=>menu[:menu] }
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

  def url_for_bookmark url
    url_for :controller => 'bookmark', :action => 'show', :uri => escape_bookmark_url(url)
  end

  def escape_bookmark_url url
    h(URI.encode(url)).gsub(/'/,'&#39;')
  end

  def header_logo_link(url = url_for(:controller => '/mypage', :action => 'index'))
    img_url = "#{@controller.request.relative_url_root}/custom/images/header_logo.png"
    "<div id=\"logo\">" + link_to(image_tag(img_url, :alt => h(Admin::Setting.abbr_app_title), :height => "45"), url) + "</div>"
  end

private
  def generate_tab_link name, options
    html_option = {:class=>'selected'} if @controller.action_name == options[:action]
    '<li>' + link_to('<span>' + name + '</span>', options, html_option) + '</li>'
  end

  def relative_url_root
    @controller.request.relative_url_root
  end

  def parse_permalink text, owner_symbol
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

    # 共有ファイルのリンクに対してtarget="_blank"を付加
    share_file_link_regex = /(<a href=\"#{root_url.gsub('\/', '\\\/')}[^\/.?]+\/[^\/.?]+\/files\/.*?\")(.*?<\/a>)/m
    text.gsub!( share_file_link_regex ) do |url|
      "#{$1} target=\"_blank\"#{$2}"
    end

    split_mark =  "&gt;"
    procs.each { |value| text = BoardEntry.replace_symbol_link(text, value.first, value.last, split_mark) }
    return text
  end

  def link_to_bookmark_url(bookmark, name = nil)
    url = bookmark.url
    title = bookmark.title

    if bookmark.is_type_page?
      url =  relative_url_root + url
      return "<a href=#{escape_bookmark_url(url)} title='#{h(title)}'>#{icon_tag('report_link')} #{h(name)}</a>"
    elsif bookmark.is_type_user?
      url =  relative_url_root + url
      return "<a href=#{escape_bookmark_url(url)} title='#{h(title)}'>#{icon_tag('user')} #{h(name)}</a>"
    else
      return "<a href=#{escape_bookmark_url(url)} title='#{h(title)}'>#{icon_tag('world_link')} #{h(truncate(name, 115))}</a>"
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
