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

class NoticesController < ApplicationController

  verify :method => :post, :only => %w(create)

  def create
    target = target_user || target_group
    if target
      current_user.notices.create :target => target
      respond_to do |format|
        format.html do
          if target_user
            redirect_to url_for(:controller => 'user', :action => 'show', :uid => target_user.uid)
          elsif target_group
            redirect_to url_for(:controller => 'group', :action => 'show', :uid => target_group.gid)
          else
            redirect_to root_url
          end
        end
      end
    else
      render_404
    end
  end

  def destroy
    notice = current_user.notices.find params[:id]
    notice.destroy
    respond_to do |format|
      format.html do
        if target_user
          redirect_to url_for(:controller => 'user', :action => 'show', :uid => target_user.uid)
        elsif target_group
          redirect_to url_for(:controller => 'group', :action => 'show', :uid => target_group.gid)
        else
          redirect_to root_url
        end
      end
    end
  end

  private
  def target_user
    @target_usr ||= User.find_by_uid params[:uid]
  end

  def target_group
    @target_group ||= Grouo.find_by_gid params[:gid]
  end
end
