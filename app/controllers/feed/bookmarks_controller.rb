class Feed::BookmarksController < Feed::ApplicationController
  def index
    @bookmarks = Bookmark.publicated.recent(10).order_new.limit(25)
    @title = _('New bookmarks')
    respond_to do |format|
      format.atom { render :action => 'index' }
    end
  end
end
