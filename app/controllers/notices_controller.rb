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

class NoticesController < ApplicationController

  def create
    target = current_target_user || current_target_group
    if target
      current_user.notices.create :target => target
      respond_to do |format|
        format.html do
          redirect_to [current_tenant, target]
        end
      end
    else
      render_404
    end
  end

  def destroy
    target = current_target_user || current_target_group
    if target
      notice = current_user.notices.find params[:id]
      notice.destroy
      respond_to do |format|
        format.html do
          redirect_to [current_tenant, target]
        end
      end
    else
      render_404
    end
  end
end
