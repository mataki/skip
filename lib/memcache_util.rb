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

require 'memcache'

class MemcacheUtil
  @@cache = MemCache::new 'localhost:11211'

  EXPIRE = 60 * 60

  # 対象のアプリから情報を取得して返す。
  # その際にmemcacheが利用可能であれば#{アプリ名_user_code}という名前でキャッシュに格納
  # キャッシュが利用できない場合はキャッシュせずに返す。
  # user_code: ユーザコード(例:123456)
  # appname: 対象のアプリ名
  # action: memcacheへ格納する情報を取得する
  def self.get(user_code, appname, action)
    if info = @@cache["#{appname}_#{user_code}"]
      return info
    end
    info = get_from_api(user_code, appname, action)
    @@cache.set("#{appname}_#{user_code}", info, EXPIRE) if info
    info
  rescue MemCache::MemCacheError => e
    ActiveRecord::Base.logger.error "[MemCache Error] #{e.message}"
    get_from_api(user_code, appname, action)
  end

  # 指定アプリのキャッシュをクリアする。
  def self.clear(user_code, appname)
    @@cache.delete("#{appname}_#{user_code}")
  rescue MemCache::MemCacheError => e
    ActiveRecord::Base.logger.error "[MemCache Error] #{e.message}"
  end

private
  def self.get_from_api(user_code, appname, action)
    info = SkipEmbedded::WebServiceUtil.open_service(appname, action, { :user_code => user_code })
    if (info and not info["error"])
      return info
    else
      return nil
    end
  end
end
