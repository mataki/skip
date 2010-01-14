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

class Admin::UserProfilesController < Admin::ApplicationController
  def edit
    user = Admin::User.find(params[:user_id])
    @profiles = user.user_profile_values
    @topics = [[_('Listing %{model}') % {:model => _('user')}, admin_users_path],
               [_('Editing %{model}') % {:model => user.name}, edit_admin_user_path(user)],
               [_('Editing %{model}') % {:model => _('user profile')}]]
    render :action => :edit
  end

  def update
    user = Admin::User.find(params[:user_id])
    @profiles = user.find_or_initialize_profiles(params[:profile_value])

    begin
      Admin::UserProfileValue.transaction do
        @profiles.each{|profile| profile.save!}
      end

      flash[:notice] = _("%{model} was successfully updated.") % {:model => _('user profile') }
      redirect_to :action => :edit
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      @error_msg = SkipUtil.full_error_messages(@profiles)
      @topics = [[_('Listing %{model}') % {:model => _('user')}, admin_users_path],
               [_('Editing %{model}') % {:model => user.name}, edit_admin_user_path(user)],
                 [_('Editing %{model}') % {:model => _('user profile')}]]
      render :action => :edit
    end
  end

  alias :show :edit
  alias :new :edit
  alias :create :update
end

