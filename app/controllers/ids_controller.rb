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
  layout false
  skip_before_filter :sso, :login_required, :prepare_session
  skip_after_filter  :remove_message

  def show
    @user = User.find_by_code(params[:user])
    raise ActiveRecord::RecordNotFound if @user.nil?

    respond_to do |format|
      format.html do
        response.headers['X-XRDS-Location'] = formatted_identity_url(:user => @user.code, :format => :xrds, :protocol => scheme)
      end
      format.xrds
    end
  end
end
