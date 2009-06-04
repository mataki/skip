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

require "resolv-replace"
require 'timeout'
require 'rss'
class CollaborationApp
  attr_reader :app_name
  def initialize app_name
    @app_name = app_name
    # TODO nilのチェックが必要
    @feed_path = SkipEmbedded::InitialSettings['collaboration_apps'][@app_name]['feed_path']
  end

  def self.enabled?
    SkipEmbedded::InitialSettings['collaboration_apps']
  end

  def self.names
    enabled? ? SkipEmbedded::InitialSettings['collaboration_apps'].map{|k, v| k} : []
  end

  def self.all_feed_items_by_user user, limit = 20
    feed_items = []
    names.each do |name|
      feed_items += CollaborationApp.new(name).feed_items_by_user(user)
    end
    feed_items.sort{|x, y| y.date <=> x.date}.slice(0...limit)
  end

  def feed_items_by_user user, group = nil
    uoa = UserOauthAccess.find_by_app_name_and_user_id(@app_name, user.id)
    uoa ? RSS::Parser.parse(uoa.resource(@feed_path)).items : []
  end

  def operations_by_view_place view_place
    operations = SkipEmbedded::InitialSettings['collaboration_apps'][@app_name]['operations']
    operations.delete_if{|f| !f['view_place'] == 'view_place'} if view_place
  end

  def feeds_by_view_place view_place
    feeds = SkipEmbedded::InitialSettings['collaboration_apps'][@app_name]['feeds']
    feeds.delete_if{|f| !f['view_place'] == 'view_place'} if view_place
  end

  def self.using
    OauthProvider.enable.map{|provider| self.new(provider.app_name) }
  end
end
