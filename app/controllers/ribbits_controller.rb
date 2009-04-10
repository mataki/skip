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

class RibbitsController < UserController
  before_filter :access_denied_other, :except => :call

  def messages
    @ribbit = @user.ribbit
  end
  alias call_history messages

  def edit
    @ribbit = @user.ribbit || @user.build_ribbit
  end
  alias new edit

  def update
    @ribbit = @user.ribbit || @user.build_ribbit
    if @ribbit.update_attributes(params[:ribbit])
      flash[:notice] = _("%{model} was successfully updated.") % { :model => _('ribbit')}
      redirect_to(:action => :edit)
    else
      render :edit
    end
  end
  alias create update

  def call
    @title = _("Call")
    if @ribbit = @user.ribbit
      render :layout => "dialog"
    else
      render :text => _("This user don't set Ribbit account.")
    end
  end

  private
  def access_denied_other
    unless @user == current_user
      flash[:error] = _('Access Denied')
      redirect_to(:controller => :user, :uid => @user.uid, :action => :show)
      false
    end
  end
end
