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

require "resolv-replace"
require 'timeout'
require 'rss'

class UserOauthAccess < ActiveRecord::Base
  include CollaborationApp::Oauth::Client
  belongs_to :users

  def resource resource_path
    # TODO タイムアウト設定は別設定にしたほうがいいかも
    timeout(Admin::Setting.mypage_feed_timeout.to_i) do
      return client(self.app_name).oauth(self.token, self.secret).get_resource(resource_path)
    end
    nil
  end

  def self.resource app_name, user, resource_path
    return '' if (!user.is_a?(User) || user.id.blank?)
    uoa = UserOauthAccess.find_by_app_name_and_user_id(app_name, user.id)
    if uoa && !uoa.token.blank?
      returning resource_body = uoa.resource(resource_path) do
        yield(true, resource_body) if block_given?
      end
    else
      returning resource_body = '' do
        user.to_s_log('[OAuth Token was not exist]')
        yield(false, resource_body) if block_given?
      end
    end
  rescue Timeout::Error, StandardError => e
    returning resource_body = '' do
      logger.error e
      e.backtrace.each { |line| logger.error line }
      yield(false, resource_body) if block_given?
    end
  end

  def self.sorted_feed_items rss_body, limit = 20
    returning [] do |items|
      items.concat(feed_items(rss_body).sort{|x, y| y.date <=> x.date}.slice(0...limit))
      yield(true, items) if block_given?
    end
  end

  def self.feed_items rss_body
    RSS::Parser.parse(rss_body).items
  rescue => e
    returning [] do
      logger.error e
      e.backtrace.each { |line| logger.error line }
    end
  end
end
