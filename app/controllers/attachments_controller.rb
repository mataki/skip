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

class AttachmentsController < ApplicationController
  include IframeUploader
  layout 'subwindow', :only => %w[index]

  before_filter :require_wiki_enabled

  def index
    @attachments = Page.find_by_title(params[:wiki_id]).attachments.paginate(:page => params[:page], :per_page => 10)
    respond_to do |format|
      format.js {
        render :json => {
          :pages => {
            :first => 1,
            :previous => @attachments.previous_page,
            :next => @attachments.next_page,
            :last => @attachments.total_pages,
            :current => @attachments.current_page,
            :item_count => @attachments.size },
        :attachments => @attachments.map{|a| {:attachment=>attachment_to_json(a)} }
        }
      }
    end
  end

  def new
    @page = Page.find_by_title(params[:wiki_id])
    @attachment = @page.attachments.build(:user_id=>current_user.id)

    render(:template=>"attachments/new_ajax_upload", :layout=>false)
  end

  def show
    @attachment = Attachment.find(params[:id])
    opts = {:filename => @attachment.display_name, :type => @attachment.content_type }
    opts[:filename] = URI.encode(@attachment.display_name) if msie?

    send_data(@attachment.send(:current_data), opts)
  end

  def create
    @error_messages = []
    unless params[:attachment]
      ajax_upload? ? render(:text => {:status => 400, :messages => [_("%{name} is mandatory.") % { :name => _('File') }]}.to_json) : render_window_close
      return
    end
    page = Page.find_by_title(params[:wiki_id])
    @attachment = page.attachments.build(params[:attachment].merge({:user_id=>current_user.id}))
    if @attachment.save
      notice_message = n_('File was successfully uploaded.', 'Files were successfully uploaded.', params[:attachment].size)
      flash[:notice] = notice_message
      ajax_upload? ? render(:text => {:status => '200', :messages => [notice_message]}.to_json) : render_window_close
    else
      logger.warn(@attachment.errors.full_messages)
      if ajax_upload?
        render(:text => {:status => '403', :messages => @attachment.errors.full_messages}.to_json)
      else
        render :action => "new"
      end
    end
  end

  private
  def attachment_to_json(atmt)
    returning(atmt.attributes.slice("content_type", "filename", "display_name")) do |json|
      json[:path] = attachment_path(atmt)
      json[:inline] = attachment_path(atmt, :position=>"inline") if atmt.image?
      # TODO I18n::MissingTranslationData (translation missing: ja, number, human, storage_units, format):
#      json[:size] = number_to_human_size(atmt.size)
      json[:size] = atmt.size

      json[:updated_at] = atmt.updated_at.strftime("%Y/%m/%d %H:%M")
      json[:created_at] = atmt.created_at.strftime("%Y/%m/%d %H:%M")
    end
  end
end
