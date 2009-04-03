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
  verify :method => :post, :only => :update

  def messages
    @messages = Ribbitter.messages(@user.uid)
  end

  def call_history
    @histories = Ribbitter.call_history(@user.uid)
  end

  def edit
    @ribbit = @user.ribbit || @user.build_ribbit
  end

  def update
    @ribbit = @user.ribbit || @user.build_ribbit
    if @ribbit.update_attributes(params[:ribbit])
      flash[:notice] = _("%{model} was successfully updated.") % { :model => _('ribbit')}
      redirect_to(:action => :edit)
    else
      render :edit
    end
  end

  def call
    @title = _("電話をかける")
    if @ribbit = @user.ribbit
      render :layout => "dialog"
    else
      render :text => _("このユーザはRibbitの利用設定を行なっておりません。")
    end
  end

end
