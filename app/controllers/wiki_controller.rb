class WikiController < ApplicationController

  def show
    @page = Page.find_by_title(params[:id])
  end

  def create
    page = Page.new(params[:page])
    if page.valid?
      Page.transaction do
        parent_page = Page.find params[:parent_id]
        parent_page.children << page
        parent_page.save
      end
      flash[:notice] = "'#{page.title}'が作成されました"
    else
      flash[:error] = page.errors.full_messages
    end

    redirect_to :back
  end

end
