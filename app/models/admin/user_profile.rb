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

class Admin::UserProfile < UserProfile
  belongs_to :user, :class_name => 'Admin::User'

  validates_format_of :join_year, :with => /^\d{4}$/, :allow_blank => true
  validates_format_of :birth_month, :with => /(^[1-9]$|10|11|12)/, :allow_blank => true
  validates_format_of :birth_day, :with => /(^[1-9]$|[1-2][0-9]|30|31)/, :allow_blank => true

  N_('Admin::UserProfile|Address 1')
  N_('Admin::UserProfile|Address 1 description')
  N_('Admin::UserProfile|Address 2')
  N_('Admin::UserProfile|Address 2 description')
  N_('Admin::UserProfile|Alma mater')
  N_('Admin::UserProfile|Alma mater description')
  N_('Admin::UserProfile|Birth day')
  N_('Admin::UserProfile|Birth day description')
  N_('Admin::UserProfile|Birth month')
  N_('Admin::UserProfile|Birth month description')
  N_('Admin::UserProfile|Blood type')
  N_('Admin::UserProfile|Blood type description')
  N_('Admin::UserProfile|Disclosure')
  N_('Admin::UserProfile|Email')
  N_('Admin::UserProfile|Email description')
  N_('Admin::UserProfile|Gender type')
  N_('Admin::UserProfile|Gender type description')
  N_('Admin::UserProfile|Hobby')
  N_('Admin::UserProfile|Hobby description')
  N_('Admin::UserProfile|Hometown')
  N_('Admin::UserProfile|Hometown description')
  N_('Admin::UserProfile|Introduction')
  N_('Admin::UserProfile|Introduction description')
  N_('Admin::UserProfile|Join year')
  N_('Admin::UserProfile|Join year description')
  N_('Admin::UserProfile|Section')
  N_('Admin::UserProfile|Section description')
  N_('Admin::UserProfile|User')
  N_('Admin::UserProfile|Extension')
  N_('Admin::UserProfile|Extension description')
  N_('Admin::UserProfile|Self introduction')
  N_('Admin::UserProfile|Self introduction description')

  def self.search_columns
    %w(email section extension)
  end

  def topic_title
    user.name
  end
end
