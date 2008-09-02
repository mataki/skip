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


class Session < ActiveRecord::Base

  def self.create_sso_sid user_info, digest_key, expire_date
    require 'uuidtools'
    sid = UUID.random_create.to_s
    digest = OpenSSL::HMAC::hexdigest(OpenSSL::Digest::SHA1.new, digest_key, sid)
    sso_sid = sprintf("sid=%s&digest=%s", sid, digest)

    Session.create(:sid => sso_sid, :user_code => user_info["code"], :user_name => user_info["name"], :user_email => user_info["email"], :user_section => user_info["section"], :expire_date => expire_date || Time.now + 1.day)
    return sso_sid
  end
end
