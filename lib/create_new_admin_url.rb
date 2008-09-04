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

class CreateNewAdminUrl < BatchBase
  include ActionController::UrlWriter
  default_url_options[:host] = ENV['SKIP_HOST'] || 'localhost:3000'
  def self.execute options = {}
    cnau = CreateNewAdminUrl.new
    if valid_args?(options)
      if activation = Activation.first
        p (code = activation.code) ? cnau.show_new_admin_url(code) : '初期アカウントは登録済みです。'
      else
        activation = Activation.new(:code => options[:code])
        p activation.save ? cnau.show_new_admin_url(activation.code) : 'ワンタイムコードの保存に失敗しました。'
      end
    end
  end

  def show_new_admin_url(code)
    first_new_admin_user_url(:code => code)
  end

  def self.valid_args?(options = {})
    unless options[:code]
      p 'ワンタイムコードの指定は必須です。'
      return false
    end
    true
  end
end
CreateNewAdminUrl.execution(:code => ARGV[0]) unless RAILS_ENV == 'test'
