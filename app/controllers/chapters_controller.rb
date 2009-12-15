class ChaptersController < ApplicationController
  layout 'wiki'
  before_filter :secret_checker

  def new
    @current_page = Page.find_by_title(params[:wiki_id])
  end

  def edit
    @current_page = Page.find_by_title(params[:wiki_id])
    @chapter = Chapter.find(params[:id])
    @num = 0
    @current_page.chapters.each do |chapter|
      break if chapter.id == @chapter.id
      @num += 1
    end
  end

  def update
    @page = Page.find_by_title(params[:wiki_id])
    content = Content.new
    new_chapter = Chapter.new
    new_chapter.data = params[:chapter][:content]

    chapters = @page.chapters
    if chapters
      chapters.each do |chapter|
        unless chapter.id == params[:id].to_i
          content.chapters.build(:data=>chapter.data) unless chapter.data.nil?
        else
          content.chapters.build(:data=>new_chapter.data) unless chapter.data.nil?
        end
      end
    end

    @history = @page.edit(content, current_user)
    if @history.save!
      flash[:notice] = "ページが更新されました"
      redirect_to wiki_path(@page.title)
    else
      errors = [@history, @history.content].map{|m| m.errors.full_messages }.flatten
      redirect_to :back
    end
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
      flash[:notice] = _("ページが更新されました")
      redirect_to wiki_path(@page.title)
    else
      errors = [@history, @history.content].map{|m| m.errors.full_messages }.flatten
      redirect_to :back
    end
  end

  def destroy
    @page = Page.find_by_title(params[:wiki_id])
    chapter_id = params[:id].to_i
    content = Content.new

    @page.chapters.each do |chapter|
      content.chapters.build(:data=>chapter.data) unless chapter.id == chapter_id
    end

    @history = @page.edit(content, current_user)
    if @history.save!
      flash[:notice] = _("セクションを削除しました")
      redirect_to wiki_path(@page.title)
    else
      errors = [@history, @history.content].map{|m| m.errors.full_messages }.flatten
      redirect_to :back
    end
  end
end
