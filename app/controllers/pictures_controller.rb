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

class PicturesController < ApplicationController

  def picture
    @picture = Picture.find(params[:id])
    send_data(@picture.data, :filename => @picture.name, :type => @picture.content_type, :disposition => "inline")
  end

  def create
    picture = current_user.build_picture(params[:picture])
    respond_to do |format|
      if picture.save
        flash[:notice] = _("Picture was updated successfully.")
      else
        flash[:warn] = picture.errors.full_messages
      end
      format.html { redirect_to url_for(:controller => 'mypage', :action => 'manage', :menu => 'manage_portrait') }
    end
  end

  def update
    picture = current_user.picture
    picture.attributes = params[:picture]
    respond_to do |format|
      if picture.save
        flash[:notice] = _("Picture was updated successfully.")
      else
        flash[:warn] = picture.errors.full_messages
      end
      format.html { redirect_to url_for(:controller => 'mypage', :action => 'manage', :menu => 'manage_portrait') }
    end
  end

  def destroy
    picture = current_user.picture
    picture.destroy
    respond_to do |format|
      flash[:notice] = _("Picture was deleted successfully.")
      format.html { redirect_to url_for(:controller => 'mypage', :action => 'manage', :menu => 'manage_portrait') }
    end
  end
end
