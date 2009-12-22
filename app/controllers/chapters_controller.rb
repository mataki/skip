class ChaptersController < ApplicationController
  layout 'wiki'
  before_filter :secret_checker

  def new
    @current_page = Page.find_by_title(params[:wiki_id])
    @chapter = Chapter.new
  end

  def insert
    @current_page = Page.find_by_title(params[:wiki_id])
    @chapter = Chapter.find(params[:id])
    @before_num = @after_num = @chapter.position
  end

  def edit
    @current_page = Page.find_by_title(params[:wiki_id])
    @chapter = Chapter.find(params[:id])
    num = @chapter.position
    @before_num, @after_num = num-1, num
  end

  def update
    @page = Page.find_by_title(params[:wiki_id])
    content = Content.new
    new_chapter = Chapter.new(:data=>params[:chapter][:content])
    current_chapter = Chapter.find(params[:id])

    chapters = @page.chapters
    if chapters
      chapters.each do |chapter|
        data = if current_chapter.position == chapter.position
                 new_chapter.data
               else
                 chapter.data
               end
        content.chapters.build(:data=>data) unless data.nil?
      end
    end

    @history = @page.edit(content, current_user)
    if @history.save!
      flash[:notice] = _("ページが更新されました")
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
      chapters.each {|chapter| content.chapters.build(:data=>chapter.data) unless chapter.data.nil? }
    end
    new_chapter = content.chapters.build(:data => params[:chapter][:content])
    new_chapter.insert_at(params[:position_id])

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

    @page.chapters.each {|chapter| content.chapters.build({:data=>chapter.data}) unless chapter.id == chapter_id }

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
