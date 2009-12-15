class HistoriesController < ApplicationController
  layout 'wiki'
  before_filter :secret_checker

  def index
    @current_page = Page.find_by_title(params[:wiki_id])
    @histories = @current_page.histories
  end

  def show
    @current_page = Page.find_by_title(params[:wiki_id])
    @history = @current_page.histories.detect{|h| h.id == params[:id].to_i }
  end

  def diff
    @current_page = Page.find_by_title(params[:wiki_id], :include => :histories)
    @diffs = @current_page.diff(params[:from], params[:to])
  end
end

