class WikiController < ApplicationController

  def show
    @page = Page.find_by_title(params[:id])
  end

end
