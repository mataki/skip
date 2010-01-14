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

class Admin::UserProfileMasterCategoriesController < Admin::ApplicationController
  include Admin::AdminModule::AdminRootModule

  def index
    redirect_to admin_masters_path
  end

  def show
    flash.keep
    redirect_to admin_user_profile_master_categories_path
  end

  def destroy
    user_profile_master_category = Admin::UserProfileMasterCategory.find(params[:id])
    if user_profile_master_category.deletable?
      user_profile_master_category.destroy
      flash[:notice] = _("%{model} was successfully deleted.") % {:model => _('user profile master category')}
    else
      message = user_profile_master_category.errors.full_messages.join('<br/>')
      flash[:error] = message unless message.blank?
    end
    respond_to do |format|
      format.html { redirect_to(admin_user_profile_master_categories_path) }
      format.xml { head :ok }
    end
  end
end
