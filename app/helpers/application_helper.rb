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

module ApplicationHelper
  include InitialSettingsHelper
  include CacheHelper
  include SkipHelper
  include HelpIconHelper

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

  def i18n_will_paginate pages, options = {}
    will_paginate pages, {:next_label => _('Next »'), :previous_label => _('« Previous')}.merge(options)
  end

  def i18n_will_paginate_with_container_wrapper pages, options = {}
    if pages && pages.total_pages > 1
      content_tag :div, :class => 'navi ui-corner-all' do
        i18n_will_paginate(pages, options)
      end
    end
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

  def owner_link_to owner, name = nil, options = {}
    name ||= "[#{owner.name}]"
    link = link_to(h(name), [current_tenant, owner], :title => name)
    if options[:with_prefix]
      prefix = owner.is_a?(User) ? 'by' : 'on'
      "#{prefix} #{link}"
    else
      link
    end
  end

  def image_link_tag title, image_name, options={}
    link_to image_tag(image_name, :alt => title) + title, options
  end

  # リッチテキストの表示
  def render_richtext(text, owner = nil)
    content = parse_permalink(text, owner)
    "<div class='rich_style ui-corner-all'>#{sanitize_and_unescape_for_richtext(content)}</div>"
  end

  def sanitize_and_unescape_for_richtext(content)
    content.gsub!(/(?:<|&lt;)!--.*?--(?:>|&gt;)/m, '') unless content.blank?
    sanitize_style_with_whitelist(BoardEntry.unescape_href(content))
  end

  def sanitize_style_with_whitelist(content)
    Sanitize.clean(content || '', Sanitize::Config::SKIP)
  end

  def translate_publication_type(entry)
    case entry.publication_type
    when 'public'
      _("Open to All")
    when 'protected'
      _("Specify Directly")
    when 'private'
      entry.diary? ? _("Owner Only") : _("Members Only")
   end
  end

  # TODO Publicationクラス辺りに移したい
  def get_publication_type_icon(entry_or_share_file)
    icon_name = ''
    view_name = ''

    case entry_or_share_file.publication_type
    when 'public'
      if entry_or_share_file.owner_is_group? and entry_or_share_file.public?
        group = Group.active.find_by_gid(entry_or_share_file.owner.gid)
        category = group ? group.group_category : nil
        icon_name = category.blank? ? "group" : category.icon
      else
        icon_name = 'user_suit'
      end
      view_name = _("Open to All")
    when 'protected'
      visibility, visibility_color = entry_or_share_file.visibility
      icon_name = 'link'
      view_name = _("Specify Directly") + visibility
    when 'private'
      icon_name = entry_or_share_file.owner_is_user? ? 'pencil' : 'key'
      view_name = entry_or_share_file.owner_is_user? ? _("Owner Only") : _("Members Only")
    end
    icon_tag(icon_name, :title => view_name)
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

  def header_logo_link(url = root_url)
    "<div id=\"logo\">" + link_to(image_tag("/custom/images/header_logo.png", :alt => h(Admin::Setting.abbr_app_title), :height => "45"), url) + "</div>"
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
      application_links.unshift(link_to(Admin::Setting.abbr_app_title, tenant_root_url(current_tenant), :class => "underline_link"))
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
        s << content_tag(:div, ("powered_by"+link_to(image_tag("/custom/images/footer_logo.png"), h(Admin::Setting.footer_image_link_url))), :class => "powered_by")
      end
    end
  end

  def shortcut_menus
    return if !current_user || current_user.groups.participating(current_user).empty?
    option_tags = [content_tag(:option, _('Move to groups joined ...'), :value => url_for({:controller => '/mypage', :action => 'group'}))]

    if groups = Group.active.participating(current_user).order_participate_recent.all(:include => :group_category) and !groups.empty?
      groups.group_by(&:group_category).sort_by{|c, g| c.sort_order}.each do |category, groups_by_category|
        option_tags << content_tag(:option, "[#{h(category.name)}]", :disabled => 'disabled', :style => 'color: gray')
        groups_by_category.each do |group|
          option_tags << content_tag(:option, "&nbsp;#{truncate(h(group.name), :length => 18)}", :value => url_for({:controller => '/group', :gid => group.gid, :action => 'show'}))
        end
      end
    end
    "<select class=\"select_navi\">#{option_tags.join('')}</select>"
  end

  def skin_themes
    %w(tile blue green silver snow sakura pink orange)
  end

private
  def relative_url_root
    ActionController::Base.relative_url_root || ''
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
end

module ActionView
  module Helpers #:nodoc:
    module UrlHelper
      def link_to_unless_current_tab(name, options = {}, html_options = {}, &block)
        link_to_unless current_page?(options), name, options, html_options do
          cls = html_options[:class] ? html_options[:class] << ' selected' : 'selected'
          link_to name, options, html_options.merge(:class => cls)
        end
      end
    end
  end
end
