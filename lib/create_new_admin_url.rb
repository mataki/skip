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

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'optparse'

class CreateNewAdminUrl < BatchBase
  include ActionController::UrlWriter
  default_url_options[:host] = ENV['SKIP_HOST'] || 'localhost:3000'
  def self.execute options = {}
    cnau = CreateNewAdminUrl.new
    option_parser = OptionParser.new
    opt = {}
    option_parser.on('--code [VAL]', '指定すると管理者ユーザ登録用のactivation_codeを発行します。またアクセス用URLを表示します。') { |v| opt[:code] = v }
    option_parser.parse!(options[:argv])

    if activation = Activation.first
      unless activation.code
        p '初期管理者ユーザは登録済みです。'
        return
      end
      unless opt.has_key?(:code)
        p 'activation_codeは発行済みです。上書きする場合は、codeを指定して下さい。現在の初期管理者登録用URLは以下の通りです。'
        p cnau.show_new_admin_url(activation.code)
        return
      end
      if activation.update_attributes(:code => opt[:code] || make_token)
        p "activation_codeを上書きしました。初期管理者登録用URLは#{cnau.show_new_admin_url(activation.code)}"
      else
        p 'ワンタイムコードの保存に失敗しました。'
      end
    else
      unless opt.has_key?(:code)
        p 'activation_codeが未発行です。--helpを参照の上、codeを指定して下さい。'
        return
      end
      activation = Activation.new(:code => opt[:code] || make_token)
      if activation.save
        p 'activation_codeを発行しました。初期管理者登録用URLは以下の通りです。'
        p cnau.show_new_admin_url(activation.code)
      else
        p 'ワンタイムコードの保存に失敗しました。'
      end
    end
  end

  def show_new_admin_url(code)
    first_new_admin_user_url(:code => code)
  end

  def self.secure_digest(*args)
    Digest::SHA1.hexdigest(args.flatten.join('--'))
  end
  def self.make_token
    secure_digest(Time.now, (1..10).map{ rand.to_s })
  end 
end
CreateNewAdminUrl.execution(:argv => ARGV) unless RAILS_ENV == 'test'
