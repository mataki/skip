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

module Admin::ApplicationHelper
  def generate_admin_tab_menu
    output = ''
    output << '<ul>'
    output << generate_tab_link( _('Data management'), admin_users_path, !(request.url.include?(admin_settings_url) || request.url.include?(admin_documents_url)) )
    output << generate_tab_link( _('Admin::SettingsController|literal'), admin_settings_path(:tab => :literal), request.url == admin_settings_url || request.url == admin_settings_url(:tab => :literal) )
    output << generate_tab_link( _('Admin::SettingsController|mail'), admin_settings_path(:tab => :mail), request.url == admin_settings_url(:tab => :mail) )
    output << generate_tab_link( _('Admin::SettingsController|other'), admin_settings_path(:tab => :other), request.url == admin_settings_url(:tab => :other) )
    output << generate_tab_link( _('Admin::SettingsController|feed'), admin_settings_path(:tab => :feed), request.url == admin_settings_url(:tab => :feed) )
    output << generate_tab_link( _('Admin::DocumentsController'), admin_documents_path, request.url.include?(admin_documents_url) )
    output << '</ul>'
  end

  def generate_box_menu
    output = ''
    output << '<ul>'
    output << generate_box_menu_link( _('user'), admin_users_path, (request.url.include?(admin_users_url) || request.url == admin_root_url))
    output << generate_box_menu_link( _('group'), admin_groups_path, request.url.include?(admin_groups_url))
    output << generate_box_menu_link( _('board entry'), admin_board_entries_path, request.url.include?(admin_board_entries_url))
    output << generate_box_menu_link( _('bookmark'), admin_bookmarks_path , request.url.include?(admin_bookmarks_url))
    output << generate_box_menu_link( _('share file'), admin_share_files_path, request.url.include?(admin_share_files_path))
    output << '</ul>'
  end

  def generate_topics_str(topics)
    topics.map do |topic|
      if topic.is_a?(Array)
        if topic.size > 1
          link_to_unless_current h(topic.shift), topic.shift
        else
          h(topic.first)
        end
      else
        h(topic)
      end
    end.join(' > ')
  end

  def generate_box_menu_link(name, path, selected = false, html_options = nil)
    if selected
      "<li>#{icon_tag('bullet_red')}<b>#{name}</b></li>"
    else
      "<li>#{icon_tag('bullet_blue')}#{link_to(name, path, html_options)}</b></li>"
    end
  end

  def help_icon_tag options = {:title => '', :content => ''}
    icon_tag 'help', :class => 'help', :title => "#{options[:title]}|#{options[:content]}"
  end

  private
  def generate_tab_link(name, path, selected = false, html_options = nil)
    html_option = {:class => 'selected'} if selected
    "<li>#{link_to('<span>' + name + '</span>', path, html_option)}</li>"
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
        InstanceTag.new(object_name, method, self, nil, options.delete(:object)).to_label_tag(text, options.merge(:object => @object))
      end
      alias_method_chain :label, :gettext
    end
  end
end
