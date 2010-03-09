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
  before_filter :free_rp_mode_required, :only => %w(edit create update)

  def show
    @user = current_tenant.users.find(params[:user_id])

    respond_to do |format|
      format.html do
        response.headers['X-XRDS-Location'] = tenant_user_id(current_tenant, @user, :format => :xrds, :protocol => scheme)
        render :layout => false
      end
      format.xrds
    end
  end

  def edit
    @openid_identifier = current_user.openid_identifiers.first || OpenidIdentifier.new
  end

  def create
    @openid_identifier = current_user.openid_identifiers.first || current_user.openid_identifiers.build
    if using_open_id?
      begin
        authenticate_with_open_id do |result, identity_url|
          if result.successful?
            @openid_identifier.url = identity_url
            if @openid_identifier.save
              flash[:notice] = _('OpenID URL was successfully set.')
              redirect_to tenant_user_id_url(current_tenant, current_user)
              return
            else
              render :edit
            end
          else
            flash.now[:error] = _("OpenId process is cancelled or failed.")
            render :edit
          end
        end
      rescue OpenIdAuthentication::InvalidOpenId
        flash.now[:error] = _("Invalid OpenID URL format.")
        render :edit
      end
    else
      flash.now[:error] = _("Please input OpenID URL.")
      render :edit
    end
  end

  alias :update :create

  private
  def free_rp_mode_required
    unless login_mode?(:free_rp)
      redirect_to_with_deny_auth edit_tenant_user_path(current_tenant, current_user)
    end
  end
end
