class ChaptersController < ApplicationController
  layout 'wiki'

  def new
    @current_page = Page.find_by_title(params[:wiki_id])
  end

  def edit
    @current_page = Page.find_by_title(params[:wiki_id])
    @chapter = Chapter.find(params[:id])
  end

  def update
  end

  def create
    @page = Page.find_by_title(params[:wiki_id])
    content = Content.new
    chapters = @page.chapters
    if chapters
      chapters.each do |chapter|
        content.chapters.build(:data=>chapter.data) unless chapter.data.nil?
      end
    end
    content.chapters.build(:data => params[:chapter][:content])
    @history = @page.edit(content, current_user)
    if @history.save!
      flash[:notice] = "ページが更新されました"
      redirect_to wiki_path(@page.title)
    else
      errors = [@history, @history.content].map{|m| m.errors.full_messages }.flatten
      redirect_to :back
    end
  end

end
