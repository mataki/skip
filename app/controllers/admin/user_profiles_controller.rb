# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008 TIS Inc.
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

class Admin::UserProfilesController < ApplicationController

  # GET /admin_user_user_profile
  # GET /admin_user_user_profile.xml
  def show
    @user = Admin::User.find(params[:user_id])
    @user_profile = @user.user_profile

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user_profile }
    end
  end

  # GET /admin_user_profiles/1/edit
  def edit
    @user = Admin::User.find(params[:user_id])
    @user_profile = @user.user_profile
  end

  # PUT /admin_user_profiles/1
  # PUT /admin_user_profiles/1.xml
  def update
    @user = Admin::User.find(params[:user_id])
    @user_profile = @user.user_profile

    respond_to do |format|
      if @user_profile.update_attributes(params[:user_profile])
        flash[:notice] = 'Admin::UserProfile was successfully updated.'
        format.html { redirect_to(admin_user_user_profile_path(@user)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user_profile.errors, :status => :unprocessable_entity }
      end
    end
  end
end
