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

class Admin::UserProfileMastersController < Admin::ApplicationController
  include Admin::AdminModule::AdminRootModule

  def index
    @user_profile_masters = Admin::UserProfileMaster.find_without_order_by_sort_order(:all,
                                                                                     :include => :user_profile_master_category,
                                                                                     :order => 'user_profile_master_categories.sort_order,user_profile_masters.sort_order')

    @topics = [_('Listing %{model}') % {:model => _('user profile masters')}]

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => objects }
    end
  end

  def show
    flash.keep
    redirect_to admin_user_profile_masters_path
  end
end
