class WikiController < ApplicationController
  layout "wiki"
  def show
    @current_page = Page.find_by_title(params[:id])
    @user = User.find(@current_page.last_modified_user_id) if @current_page.has_history?
  end

  def update
    if page = Page.find_by_title(params[:id]) and !page.deleted?
      page.update_attributes(params[:page])
      flash[:notice] = "'#{page.title}'に変更されました"
    end
    redirect_to :action => :show , :id => page.title
  end

  def create
    page = Page.new(params[:page])
    page.last_modified_user_id = current_user.id

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

  def recovery
    @current_page = Page.find_by_title(params[:id])
    if @current_page.recover
      flash[:notice] = _("復旧が完了しました")
      redirect_to(wiki_path(@current_page.title))
    end
  end

  def destroy
    @current_page = Page.find_by_title(params[:id])
    if !@current_page.root? and @current_page.logical_destroy
      flash[:notice] = _("削除が完了しました")
    else
      flash[:warn] = _("削除に失敗しました")
    end

    redirect_to(wiki_path(@current_page.title))
  end

end
