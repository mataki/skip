class Feed::BoardEntriesController < Feed::ApplicationController
  def questions
    @entries = BoardEntry.publication_type_eq('public').question.visible.order_new.limit(25)
    if @entries.empty?
      head :not_found
      return
    end
    @title = _('Recent Questions')
    respond_to do |format|
      format.rss { render :action => 'index.rxml' }
      format.atom { render :action => 'index' }
    end
  end

  def timelines
    @entries = BoardEntry.publication_type_eq('public').timeline.order_new.limit(25)
    if @entries.empty?
      head :not_found
      return
    end
    @title = _('Entries')
    respond_to do |format|
      format.rss { render :action => 'index.rxml' }
      format.atom { render :action => 'index' }
    end
  end

  def popular_blogs
    # TODO recentの10日がDRYじゃない(mypage#recent_dayと同じ)
    @entries = BoardEntry.publication_type_eq('public').timeline.diary.recent(10.day).order_access.order_new.limit(25)
    if @entries.empty?
      head :not_found
      return
    end
    @title = _('Recent Popular Blogs')
    respond_to do |format|
      format.rss { render :action => 'index.rxml' }
      format.atom { render :action => 'index' }
    end
  end
end
