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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::GroupsController, 'GET /new' do
  before do
    admin_login
  end
  it 'UnknownActionになること' do
    lambda do
      get :new
    end.should raise_error(ActionController::UnknownAction)
  end
end

describe Admin::GroupsController, 'POST /create' do
  before do
    admin_login
  end
  it 'UnknownActionになること' do
    lambda do
      post :create
    end.should raise_error(ActionController::UnknownAction)
  end
end

describe Admin::GroupsController, 'GET /edit' do
  before do
    admin_login
  end
  it 'UnknownActionになること' do
    lambda do
      get :edit
    end.should raise_error(ActionController::UnknownAction)
  end
end

describe Admin::GroupsController, 'PUT /update' do
  before do
    admin_login
  end
  it 'UnknownActionになること' do
    lambda do
      put :update
    end.should raise_error(ActionController::UnknownAction)
  end
end
