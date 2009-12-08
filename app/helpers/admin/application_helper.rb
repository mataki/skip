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

module Admin::ApplicationHelper
  include HelpIconHelper
  def generate_admin_tab_menu
    output = ''
    output << '<ul>'
    output << generate_tab_link( s_('Admin::SettingsController|main'), admin_settings_path(:tab => :main), request.url == admin_settings_url(:tab => :main) || request.url == admin_root_url)
    output << generate_tab_link( _('Master data management'), admin_masters_path, request.url.include?(admin_masters_url) )
    output << generate_tab_link( _('User management'), admin_users_path, request.url.include?(admin_users_url) )
    output << generate_tab_link( _('Data management'), admin_groups_path, data_management_urls.any? { |url| request.url.include? url } )
    output << generate_tab_link( _('Admin::ImagesController'), admin_images_path, request.url.include?(admin_images_url) )
    output << generate_tab_link( _('Admin::DocumentsController'), admin_documents_path, request.url.include?(admin_documents_url) )
    output << generate_tab_link( s_('Admin::SettingsController|feed'), admin_settings_path(:tab => :feed), request.url == admin_settings_url(:tab => :feed) )
    output << generate_tab_link( s_('Admin::SettingsController|security'), admin_settings_path(:tab => :security), request.url == admin_settings_url(:tab => :security) )
    output << generate_tab_link( _('Admin::OauthProvidersController'), admin_oauth_providers_path, request.url.include?(admin_oauth_providers_url) ) unless OauthProvider.count.zero?
    output << '</ul>'
  end

  def generate_topics_str(topics)
    topics.map do |title, link|
      link_to_if link, h(title), link
    end.join(' > ')
  end

  def generate_box_menu_link(name, path, selected = false, html_options = nil)
    if selected
      "<li>#{icon_tag('bullet_red')}<b>#{name}</b></li>"
    else
      "<li>#{icon_tag('bullet_blue')}#{link_to(name, path, html_options)}</li>"
    end
  end

  def system_summary
    "#{QuotaValidation::FileSizeCounter.per_system/1.megabyte}" + " / " + "#{SkipEmbedded::InitialSettings['max_share_file_size_of_system']/1.megabyte}"
  end

  def warning_size
    file_size = "#{QuotaValidation::FileSizeCounter.per_system/1.megabyte}".to_f
    max_system_size = "#{SkipEmbedded::InitialSettings['max_share_file_size_of_system']/1.megabyte}".to_f
    (file_size / max_system_size) > 0.80
  end

  private
  def generate_tab_link(name, path, selected = false, html_options = nil)
    html_option = {:class => 'selected'} if selected
    "<li>#{link_to('<span>' + name + '</span>', path, html_option)}</li>"
  end

  def data_management_urls
    ary = []
    ary << admin_groups_url
    ary << admin_board_entries_url
    ary << admin_bookmarks_url
    ary << admin_share_files_url
    ary << admin_pictures_url
    ary
  end

end

module ActionView
  module Helpers
    module FormHelper
      include GetText
      def label_with_gettext(object_name, method, text = nil, options = {})
        text ||= s_("#{object_name.to_s.classify}|#{method.to_s.humanize}")
        # ラベル名変換が終わったらテーブル名の単数形にしておく。(for属性のため)
        object_name = object_name.to_s.demodulize.tableize.singularize
        InstanceTag.new(object_name, method, self, options.delete(:object)).to_label_tag(text, options.merge(:object => @object))
      end
      alias_method_chain :label, :gettext
    end
  end
end
