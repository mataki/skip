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

module CollaborationApp
  class Setting
    VIEW_PLACE_MYPAGE = 'mypage'
    VIEW_PLACE_GROUP = 'group'

    VIEW_PLACES = [VIEW_PLACE_MYPAGE, VIEW_PLACE_GROUP].freeze

    attr_reader :app_name, :description, :name, :root_url, :ca_file, :feeds

    def initialize app_name
      @app_name = app_name
      app_config = SkipEmbedded::InitialSettings['collaboration_apps'][@app_name]
      @description = app_config ? app_config['description'] : ''
      @name = app_config ? app_config['name'] : ''
      @root_url = app_config ? app_config['root_url'] : ''
      @ca_file = app_config ? app_config['ca_file'] : ''
      @feeds = app_config ? app_config['feeds'] : []
      @operations = app_config && app_config['operations'] ? app_config['operations'] : []
    end

    # TODO 回帰テストを書く
    def operations view_place = nil
      (view_place && VIEW_PLACES.include?(view_place)) ?  @operations.dup.select{|o| o['view_place'] == view_place} : @operations
    end
  end
end


