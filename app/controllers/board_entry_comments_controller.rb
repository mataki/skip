class BoardEntryCommentsController < ApplicationController
  include AccessibleBoardEntry
  before_filter :required_accessible_entry, :only => %w(create)
  before_filter :required_full_accessible_comment, :only => %w(update destroy)
  after_filter :make_comment_message, :only => %w(create)

  def create
    @board_entry_comment = current_target_entry.board_entry_comments.build(params[:board_entry_comment])
    @board_entry_comment.user = current_user
    if @board_entry_comment.save
      respond_to do |format|
        format.js { render :partial => "board_entry_comment", :locals => { :comment => @board_entry_comment } }
      end
    else
      respond_to do |format|
        format.js { render(:text => _('Failed to save the data.'), :status => :bad_request) }
      end
    end
  end

  def update
    @board_entry_comment.update_attribute :contents, params[:board_entry_comment][:contents]
    respond_to do |format|
      format.js { render :partial => "comment_contents", :locals =>{ :comment => @board_entry_comment } }
    end
  end

  def destroy
    unless @board_entry_comment.children.size == 0
      respond_to do |format|
        format.html do
          flash[:warn] = _("This comment cannot be deleted since it has been commented.")
          redirect_to [current_tenant, current_target_owner, current_target_entry]
          return
        end
      end
    end
    @board_entry_comment.destroy
    respond_to do |format|
      format.html do
        flash[:notice] = _("Comment was successfully deleted.")
        redirect_to [current_tenant, current_target_owner, current_target_entry]
      end
    end
  end

  private
  def current_target_comment
    @board_entry_comment ||= BoardEntryComment.find(params[:id])
  end

  def required_full_accessible_comment board_entry_comment = current_target_comment
    if result = board_entry_comment.full_accessible?(current_user)
      yield if block_given?
    else
      respond_to do |format|
        format.html { redirect_to_with_deny_auth }
        format.js { render :text => _('Operation unauthorized.'), :status => :forbidden }
      end
    end
    result
  end

  def make_comment_message
    unless current_target_entry.writer?(current_user.id)
      SystemMessage.create_message :message_type => 'COMMENT', :user_id => current_target_entry.user.id, :message_hash => {:board_entry_id => current_target_entry.id}
    end
  end
end
