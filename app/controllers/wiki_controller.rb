# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

class WikiController < ApplicationController
  layout "wiki"
  before_filter :secret_checker

  def show
    @current_page = Page.find_by_title(params[:id])
    @user = User.find(@current_page.last_modified_user_id) if @current_page.has_history?
  end

  def update
    if page = Page.find_by_title(params[:id]) and !page.deleted?
      page.update_attributes(params[:page])
      flash[:notice] = _("'#{page.title}'に変更されました")
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
