class AttachmentsController < ApplicationController
  include IframeUploader

  def new
    chapter = Chapter.find(params[:id])
    @attachment = chapter.attachments.build(:user_id=>current_user.id)

    ajax_upload?  ? render(:template=>"attachments/new_ajax_upload", :layout=>false) : render(:text => "hoge")
  end

  def create
    @error_messages = []
    unless params[:attachment]
      ajax_upload? ? render(:text => {:status => 400, :messages => [_("%{name} is mandatory.") % { :name => _('File') }]}.to_json) : render_window_close
      return
    end
    @attachment = Attachment.new(params[:attachment].merge({:user_id=>current_user.id}))
    if @attachment.save
      notice_message = n_('File was successfully uploaded.', 'Files were successfully uploaded.', params[:attachment].size)
      flash[:notice] = notice_message
      ajax_upload? ? render(:text => {:status => '200', :messages => [notice_message]}.to_json) : render_window_close
    else
      logger.warn(@attachment.errors.full_messages)
      if ajax_upload?
        render :template => "attachments/validation_error"
     else
        render :action => "new"
     end
    end
  end
end
