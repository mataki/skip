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

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
# ruby lib/batch_make_ranking.rb で実行すると利用しているSymbolクラスがRubyのSymbolクラスになってしまい
# 定数が定義されていないエラーになってしまう。そもそもSymbolというクラス名が良くない。。。
require File.expand_path(File.dirname(__FILE__) + "/symbol")

class BatchBase
  include ActionController::UrlWriter
  default_url_options[:host] = SkipEmbedded::InitialSettings['host_and_port']
  default_url_options[:protocol] = SkipEmbedded::InitialSettings['protocol']

  @@logger = Logger.new(SkipEmbedded::InitialSettings['batch_log_path'])

  include GetText
  bindtextdomain("skip", { :path => File.join(RAILS_ROOT, "locale")})
  textdomain_to(ActionView::Base, "skip") if defined? ActionView::Base
  textdomain_to(ActionMailer::Base, "skip") if defined? ActionMailer::Base

  def self.execution options = {}
    I18n.locale = SkipEmbedded::InitialSettings['default_locale'].to_sym

    starttime = Time.now
    log_info "[START] <#{self.to_s}> --- start batch (#{starttime.to_s})"

    options.store(:logger, @@logger)
    self.execute options

    runtime = Time.now - starttime
    log_info "[END]   <#{self.to_s}> ---   end batch (#{Time.now.to_s}) [benchmark:%.2fsec]" % [runtime.to_f]
  end

  def self.log_info msg
    @@logger.info msg
  end

  def self.log_warn msg
    @@logger.warn msg
  end

  def self.log_debug msg
    @@logger.debug msg
  end

  def self.log_error msg
    @@logger.error msg
  end
end
