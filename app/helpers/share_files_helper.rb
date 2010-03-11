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

module ShareFilesHelper

  def share_file_search_links_tag comma_tags, options = {}
    return '' if comma_tags.blank?
    tag_links = comma_tags.split(',').map do |tag|
      link_to h(tag), {:controller => 'search', :action => 'share_file_search', :tag_words => h(tag)}, :class => 'tag'
    end
    if max = options[:max] and max > 0
      toggle_links(tag_links, max)
    else
      tag_links.join('&nbsp;')
    end
  end

  # ファイルダウンロードへのリンク
  def file_link_to share_file, options = {}, html_options = {}
    file_name = options[:truncate] ? truncate(share_file.file_name, options[:truncate]) : share_file.file_name
    link_to h(file_name), [current_tenant, share_file.owner, share_file], html_options
  end

  def file_link_url share_file, options = {}
    share_file = ShareFile.new share_file if share_file.is_a? Hash
    url_options = {}
    url_options[:inline => true] if options[:inline]
    polymorphic_url [current_tenant, share_file.owner, share_file], url_options
  end

end
