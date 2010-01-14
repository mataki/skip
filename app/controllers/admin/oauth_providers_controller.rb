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

class Admin::OauthProvidersController < Admin::ApplicationController
  def index
    @oauth_providers = Admin::OauthProvider.all
    @topics = [_(self.class.name.to_s)]
  end

  def toggle_status
    @oauth_provider = Admin::OauthProvider.find(params[:id])
    @oauth_provider.toggle_status
    flash[:notice] = _("%{model} was successfully updated.") % {:model => _('Admin::OauthProvider')}
    redirect_to admin_oauth_providers_path
  end

  private
  def topics
    [[_('Admin::OauthProvidersController'), admin_oauth_providers_path]]
  end
end
