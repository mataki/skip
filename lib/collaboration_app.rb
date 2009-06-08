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

class CollaborationApp
  attr_reader :app_name, :base_url
  def initialize app_name
    @app_name = app_name
    app_setting = SkipEmbedded::InitialSettings['collaboration_apps'][@app_name]
    @base_url = app_setting ? app_setting['url'] : ''
  end

  # TODO 回帰テストを書く
  def operations_by_view_place view_place
    operations = SkipEmbedded::InitialSettings['collaboration_apps'][@app_name]['operations'] || []
    operations.dup.delete_if{|f| !(f['view_place'] == view_place)} if view_place
  end

  # TODO 回帰テストを書く
  def feed_settings
    feeds = SkipEmbedded::InitialSettings['collaboration_apps'][@app_name]['feeds'] || []
  end
end
