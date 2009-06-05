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
  attr_reader :app_name, :base_url
  def initialize app_name, resource_path = nil
    @app_name = app_name
    app_setting = SkipEmbedded::InitialSettings['collaboration_apps'][@app_name]
    @base_url = app_setting ? app_setting['url'] : ''
    # TODO feed_items_by_userの引き数にする
    @resource_path = resource_path
  end

  def self.enabled?
    SkipEmbedded::InitialSettings['collaboration_apps']
  end

  def self.names
    enabled? ? SkipEmbedded::InitialSettings['collaboration_apps'].map{|k, v| k} : []
  end

  # TODO 使ってない。全連携アプリのフィードを統合する必要がないなら消す
  def self.all_feed_items_by_user user, limit = 20
    feed_items = []
    names.each do |name|
      CollaborationApp.new(name).feed_items_by_user(user) do |result, items|
        feed_items += items if result
      end
    end
    feed_items.sort{|x, y| y.date <=> x.date}.slice(0...limit)
  end

  def feed_items_by_user user, limit = 20, &block
    uoa = UserOauthAccess.find_by_app_name_and_user_id(@app_name, user.id)
    if uoa
      resource = RSS::Parser.parse(uoa.resource(@resource_path))
      yield(true, resource.items.sort{|x, y| y.date <=> x.date}.slice(0...limit))
    else
      yield(false, [])
    end
  rescue => e
    ::Rails.logger.error(e)
    e.backtrace.each { |line| ::Rails.logger.error line}
    yield(false, [])
  end

  # TODO 回帰テストを書く
  def operations_by_view_place view_place
    operations = SkipEmbedded::InitialSettings['collaboration_apps'][@app_name]['operations'] || []
    operations.delete_if{|f| !(f['view_place'] == view_place)} if view_place
  end

  # TODO 回帰テストを書く
  def feeds_by_view_place view_place
    feeds = SkipEmbedded::InitialSettings['collaboration_apps'][@app_name]['feeds'] || []
    feeds.delete_if{|f| !(f['view_place'] == view_place)} if view_place
  end

  def self.using
    OauthProvider.enable.map{|provider| self.new(provider.app_name) }
  end
end
