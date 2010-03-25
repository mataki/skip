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

class IdsController < ApplicationController
  skip_before_filter :sso, :only => %w(show)
  skip_before_filter :login_required, :only => %w(show)
  skip_before_filter :prepare_session, :only => %w(show)
  skip_before_filter :valid_tenant_required, :only => %w(show)
  skip_before_filter :verify_authenticity_token, :only => %w(create update)

  def show
    @user = current_tenant.users.find(params[:id])

    respond_to do |format|
      format.html do
        response.headers['X-XRDS-Location'] = tenant_user_id(current_tenant, @user, :format => :xrds, :protocol => scheme)
        render :layout => false
      end
      format.xrds
    end
  end
end
