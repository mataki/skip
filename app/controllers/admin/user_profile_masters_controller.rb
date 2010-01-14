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

class Admin::UserProfileMastersController < Admin::ApplicationController
  include Admin::AdminModule::AdminRootModule

  def index
    @user_profile_masters = Admin::UserProfileMaster.all(:include => :user_profile_master_category,
                                                         :order => 'user_profile_master_categories.sort_order,user_profile_masters.sort_order').paginate(:page => params[:page], :per_page => 100)

    @topics = [_('Listing %{model}') % {:model => _('user profile master')}]

    redirect_to admin_masters_path
  end

  def show
    flash.keep
    redirect_to admin_user_profile_masters_path
  end
end
