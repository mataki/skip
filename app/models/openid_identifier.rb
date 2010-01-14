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

class OpenidIdentifier < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :url
  validates_uniqueness_of :url, :case_sensitive => false

  def validate
    normalize_ident_url
  rescue OpenIdAuthentication::InvalidOpenId => e
    errors.add(:url, _('has an invalid format.'))
  end

  def before_save
    self.url = normalize_ident_url
  end

  def user_with_unused
    User.find_without_retired_skip(:first, :conditions => {:id => user_id})
  end

private
  def normalize_ident_url
    OpenIdAuthentication.normalize_identifier(url) unless url.blank?
  end
end
