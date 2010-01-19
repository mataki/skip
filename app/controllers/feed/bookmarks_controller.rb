class Feed::BookmarksController < Feed::ApplicationController
  def index
    @bookmarks = Bookmark.publicated.recent(10).order_new.limit(25)
    if @bookmarks.empty?
      head :not_found
      return
    end
    @title = _('New bookmarks')
    respond_to do |format|
      format.rss { render :action => 'index.rxml' }
      format.atom { render :action => 'index' }
    end
  end
end
