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

module EditHelper
  def share_file_uploader_opt board_entry
    {
      :share_files_url => share_files_url(board_entry.symbol),
      :image_extensions => ShareFile::CONTENT_TYPE_IMAGES.keys,
      :message => {
        :title => _('Insert share file as image or link'),
        :close => _('Close'),
        :reload => _('Reload'),
        :share_files => {
          :title => _('Avalilable share files'),
          :thumbnail => _('Thumbnail'),
          :display_name => _('Filename'),
          :first => _('First page'),
          :previous => _('Previous page'),
          :next => _('Next page'),
          :last => _('Last page')
        },
        :insert_link_label =>  _('Insert link'),
        :insert_image_link_label => _('Insert image'),
        :upload_share_file => _('Upload share file')
      },
      :uploader => {
        :target => IframeUploader::UPLOAD_KEY,
        :src => {
          :form => url_for(:controller => 'share_file', :action => 'new', :owner_symbol => board_entry.symbol, :ajax_upload => 1, :escape => false),
          # HTTPS環境で、IE6を利用するとtargetが空だとHTTPへのアクセスと判断してアラートが表示されるため
          # http://support.microsoft.com/kb/261188/ja
          :target => '/blank.html'
        },
        :callback => nil,
        :trigger => 'submit'
      }
    }
  end

  def send_mail_check_box_tag
    if SkipEmbedded::InitialSettings['mail']['show_mail_function']
      result = ''
      result << check_box(:board_entry, :send_mail)
      result << label(:board_entry, :send_mail, _('Send email to accessible members'))
      result << _('(Will not be sent when the entry is limited to owner only)')
      content_tag :span, result, :class => 'send_mail_field'
    end
  end

  private
  def share_files_url symbol
    symbol_type, symbol_id = Symbol.split_symbol symbol
    raise ArgumentError, 'Symbol type is invalid.' unless %w(uid gid).include?(symbol_type)
    url_for :controller => 'share_file', :action => 'list', symbol_type.to_sym => symbol_id, :format => 'js'
  end
end
