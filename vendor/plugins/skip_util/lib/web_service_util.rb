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

# アプリケーション連携用のライブラリ
# 別のWebアプリを呼び出す際は、WebServiceUtilを利用する
# 呼び出されるサービスを定義する際は、ForServicesModuleをincludeする
require 'open-uri'
require 'logger'
require 'uri'
require 'json_parser'

class WebServiceUtil

  # 別のWebアプリのWeb-APIをコールするためのユーティリティメソッド
  # Webアプリ連携の際は、このメソッドを経由して利用すること
  # 引数:app_name = 呼び出したいWebアプリケーションのシンボル
  # 　　:service_name = 呼び出したいWeb-APIの名前
  # 　　:params = 呼び出す際のパラメータ
  # 　　:controller_name = サービスのコントローラパス（デフォルトの規約は"services"）
  #      services以外を指定も可能だが、それは茨の道と思へ
  def self.open_service app_name, service_name, params={}, controller_name="services"
    result_json = nil
    evn_url_key = app_name.to_s.upcase + '_URL'
    url = "#{ENV[evn_url_key]}/#{controller_name}/#{service_name}?"
    begin
      if params != {}
        param_str = ""
        sorted_params = params.sort_by{ |key, value| key.to_s }
        params_size = index_count = sorted_params.size
        sorted_params.each do |key, value|
          value ||= ""
          param_str << "&" if index_count != params_size
          param_str << "#{key}=" + URI.encode(URI.encode(value.to_s), /[\&|\+|\=|!|~|'|(|)|;|\/|?|:|$|,|\[|\]|]/)
          index_count = index_count - 1
        end
        url << param_str if param_str.size > 0
      end

      request_headers = { "X-SECRET-KEY" => ENV['SECRET_KEY'] }
      open(url, request_headers) {|f| f.each_line {|line| result_json = JsonParser.new.parse(line) } }
    rescue Exception => ex
      # TODO ログの出力先が、productionモードなどを意識できていない
      Logger.new("#{RAILS_ROOT}/log/#{RAILS_ENV}.log").warn "[warn]#{ex.to_s}"
    end
    result_json
  end

end

module ForServicesModule
  def check_secret_key
    unless request.env["HTTP_X_SECRET_KEY"] && request.env["HTTP_X_SECRET_KEY"] == ENV['SECRET_KEY']
      render :text => { :error => "不正なアクセスです" }.to_json
      return false
    end
  end
end

