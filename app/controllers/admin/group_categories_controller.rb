# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2010 TIS Inc.
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

class Admin::GroupCategoriesController < Admin::ApplicationController
  include Admin::AdminModule::AdminRootModule

  def index
    redirect_to admin_masters_path
  end

  def show
    flash.keep
    redirect_to admin_group_categories_path
  end

  def destroy
    group_category = Admin::GroupCategory.find(params[:id])
    if group_category.deletable?
      group_category.destroy
      flash[:notice] = _('Deletion complete.')
    else
      message = ''
      group_category.errors.full_messages.each{|msg| message += msg + '<br/>'}
      flash[:error] = message unless message.blank?
    end
    respond_to do |format|
      format.html { redirect_to(admin_group_categories_path) }
      format.xml  { head :ok }
    end
  rescue ActiveRecord::RecordNotFound => e
    flash[:error] = _('Category to be deleted does not exist.')
    respond_to do |format|
      format.html { redirect_to(admin_group_categories_path) }
      format.xml  { head :not_found }
    end
  end
end
