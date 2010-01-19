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

class OpenIdRequest < ActiveRecord::Base
  validates_presence_of :token
  validates_presence_of :parameters

  before_validation_on_create :make_token

  serialize :parameters, Hash

  def parameters=(params)
    self[:parameters] = params.is_a?(Hash) ? params.delete_if { |k,v| k.index('openid.') != 0 } : nil
  end

  private

  def make_token
    self.token = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end

end
