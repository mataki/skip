class HistoriesController < ApplicationController
  layout 'wiki'
  def new
    @page = Page.find_by_title(params[:wiki_id])
  end

  def create
    @page = Page.find_by_title(params[:wiki_id])
    @history = @page.edit(params[:history][:content], current_user)
    if @history.save
      flash[:notice] = "ページが更新されました"
      redirect_to wiki_path(@page.title)
    else
      errors = [@history, @history.content].map{|m| m.errors.full_messages }.flatten
      redirect_to :back
    end
  end
end

