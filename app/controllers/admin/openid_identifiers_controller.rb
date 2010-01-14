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

class Admin::OpenidIdentifiersController < Admin::ApplicationController
  before_filter :load_parent
  include Admin::AdminModule::AdminChildModule

  def edit
    object = chiled_objects.find(params[:id])
    set_singularize_instance_val object

    @topics = [[_('Listing %{model}') % {:model => _(object_name_without_admin(load_parent).gsub('_', ' '))}, parent_index_path],
               [_('Editing %{model}') % {:model => load_parent.topic_title}, edit_admin_user_path(load_parent)],
               _('Editing %{model}') % {:model => object.topic_title}]
  end

  def update
    object = chiled_objects.find(params[:id])
    set_singularize_instance_val object

    respond_to do |format|
      if object.update_attributes(params[admin_params_sym])
        flash[:notice] = _('%{model} was successfully updated.') % {:model => _(singularize_name.gsub('_', ' '))}
        format.html { redirect_to(edit_admin_user_path(@user)) }
        format.xml  { head :ok }
      else
        @topics = [[_('Listing %{model}') % {:model => _(object_name_without_admin(load_parent).gsub('_', ' '))}, parent_index_path],
                   [_('Editing %{model}') % {:model => load_parent.topic_title}, edit_admin_user_path(load_parent)],
                   _('Editing %{model}') % {:model => object.topic_title}]

        format.html { render :action => "edit" }
        format.xml  { render :xml => object.errors, :status => :unprocessable_entity }
      end
    end
  end

  private
  def load_parent
    @user ||= Admin::User.find(params[:user_id])
  end

  def url_prefix
    'admin_user_'
  end
end
