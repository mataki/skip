class Admin::BoardEntryCommentsController < ApplicationController
  before_filter :require_admin, :load_parent
  include AdminModule::AdminChildModule

  private
  def load_parent
    @board_entry ||= Admin::BoardEntry.find(params[:board_entry_id])
  end

  def url_prefix
    'admin_board_entry_'
  end
end
