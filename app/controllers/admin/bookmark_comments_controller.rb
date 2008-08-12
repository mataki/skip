class Admin::BookmarkCommentsController < ApplicationController
  before_filter :require_admin, :load_parent
  include AdminModule::AdminChildModule

  private
  def load_parent
    @bookmark ||= Admin::Bookmark.find(params[:bookmark_id])
  end

  def url_prefix
    'admin_bookmark_'
  end
end
