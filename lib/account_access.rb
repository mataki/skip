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

class AccountAccess

  class AccountAccessException < Exception
  end

  def self.auth(user_code, password)
    if user = User.auth(user_code, password)
      return { 'code' => user.code, 'name' => user.name, 'email' => user.user_profie.email, 'section' => user.user_profie.section}
    end
    raise AccountAccessException.new({ "message" => "ログインに失敗しました。", "detail" => "下部に記載されているお問い合わせ先にご連絡下さい。"})
  end

  def self.change_password(user_code, user_params)
    user = User.auth(user_code, user_params[:old_password])
    unless user
      user = User.new(user_params)
      user.errors.add(:old_password, 'が間違っています。')
      return user
    end
    user.attributes = user_params
    user.save
    user
  end
end
