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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::OauthProvider, '#toggle_status' do
  describe 'まだ有効になっていない場合' do
    before do
      @oauth_provider = Admin::OauthProvider.create! :app_name => 'app_name'
    end
    it '有効になること' do
      lambda do
        @oauth_provider.toggle_status
      end.should change(@oauth_provider, :enable).from(false).to(true)
    end
  end
  describe '既に有効になっている場合' do
    before do
      @oauth_provider = Admin::OauthProvider.create! :app_name => 'app_name' do |o|
        o.enable = true
      end
    end
    it '無効になること' do
      lambda do
        @oauth_provider.toggle_status
      end.should change(@oauth_provider, :enable).from(true).to(false)
    end
  end
end
