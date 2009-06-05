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
  def initialize app_name
    @app_name = app_name
    app_setting = SkipEmbedded::InitialSettings['collaboration_apps'][@app_name]
    @base_url = app_setting ? app_setting['url'] : ''
  end

  def self.enable
    OauthProvider.enable.map{|provider| self.new(provider.app_name) }
  end

  def self.sorted_feed_items rss_body, limit = 20, &block
    returning [] do |items|
      rss = RSS::Parser.parse(rss_body)
      items.concat(feed_items(rss_body).sort{|x, y| y.date <=> x.date}.slice(0...limit))
      yield(true, items) if block_given?
    end
  end

  def self.feed_items rss_body
    RSS::Parser.parse(rss_body).items
  rescue => e
    returning [] do
      ::Rails.logger.error(e)
      e.backtrace.each { |line| ::Rails.logger.error line}
    end
  end

  def resource user, resource_path, &block
    return '' if (!user.is_a?(User) || user.id.blank?)
    uoa = UserOauthAccess.find_by_app_name_and_user_id(@app_name, user.id)
    if uoa
      returning resource_body = uoa.resource(resource_path) do
        yield(true, resource_body) if block_given?
      end
    else
      returning resource_body = '' do
        user.to_s_log('[OAuth Token was not exist]')
        yield(false, resource_body) if block_given?
      end
    end
  rescue => e
    returning resource_body = '' do
      ::Rails.logger.error(e)
      e.backtrace.each { |line| ::Rails.logger.error line}
      yield(false, resource_body) if block_given?
    end
  end

  # TODO 回帰テストを書く
  def operations_by_view_place view_place
    operations = SkipEmbedded::InitialSettings['collaboration_apps'][@app_name]['operations'] || []
    operations.dup.delete_if{|f| !(f['view_place'] == view_place)} if view_place
  end

  # TODO 回帰テストを書く
  def feeds_by_view_place view_place
    feeds = SkipEmbedded::InitialSettings['collaboration_apps'][@app_name]['feeds'] || []
    feeds.dup.delete_if{|f| !(f['view_place'] == view_place)} if view_place
  end
end
