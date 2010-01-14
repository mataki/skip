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
require 'optparse'

class CreateNewAdminUrl < BatchBase
  def self.execute options = {}
    cnau = CreateNewAdminUrl.new
    option_parser = OptionParser.new
    opt = {}
    option_parser.on('--code [VAL]', _('Issues activation_code for registering administrative user. It also shows the URL to access.')) { |v| opt[:code] = v }
    option_parser.parse!(options[:argv])

    if activation = Activation.first
      unless activation.code
        p _('Initial administrative user has already been registered.')
        return
      end
      unless opt.has_key?(:code)
        p _('activation_code has already been issued. Specify --code to overwrite. The current URL for registering initial administrative user as follows:')
        p cnau.show_new_admin_url(activation.code)
        return
      end
      if activation.update_attributes(:code => opt[:code] || make_token)
        p _("Overwritten activation_code. The current URL for registering initial administrative user is %s.") % cnau.show_new_admin_url(activation.code)
      else
        p _('Failed to save one-time code.')
      end
    else
      unless opt.has_key?(:code)
        p _('activation_code has not been issued. Refer to --help and specify --code.')
        return
      end
      activation = Activation.new(:code => opt[:code] || make_token)
      if activation.save
        p _('Issued activation_code. The URL for registering initial administrative user as follows:')
        p cnau.show_new_admin_url(activation.code)
      else
        p _('Failed to save one-time code.')
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
