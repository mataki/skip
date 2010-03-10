class EntryTrackbacksController < ApplicationController
  include AccessibleBoardEntry
  before_filter :required_full_accessible_entry, :only => [:destroy]

  def destroy
    @board_entry.entry_trackbacks.find(params[:id]).destroy
    respond_to do |format|
      format.html do
        flash[:notice] = _("Specified trackback was deleted successfully.")
        redirect_to [current_tenant, current_target_owner, @board_entry]
      end
    end
  end
end
