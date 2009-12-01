class WikiController < ApplicationController
  layout "wiki"
  def show
    @page = Page.find_by_title(params[:id])
    @user = User.find(@page.last_modified_user_id) if @page.has_history?
  end

  def update
    if page = Page.find_by_title(params[:id])
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

end
