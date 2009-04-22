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

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

class BatchBase
  include ActionController::UrlWriter
  default_url_options[:host] = Admin::Setting.host_and_port_by_initial_settings_default
  default_url_options[:protocol] = Admin::Setting.protocol_by_initial_settings_default

  @@logger = Logger.new(ENV['BATCH_LOG_PATH'])

  def self.execution options = {}
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
