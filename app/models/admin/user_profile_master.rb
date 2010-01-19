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

class Admin::UserProfileMaster < UserProfileMaster

  N_('Admin::UserProfileMaster|User profile master category')
  N_('Admin::UserProfileMaster|User profile master category description')
  N_('Admin::UserProfileMaster|Name')
  N_('Admin::UserProfileMaster|Name description')
  N_('Admin::UserProfileMaster|Input type')
  N_('Admin::UserProfileMaster|Input type description')
  N_('Admin::UserProfileMaster|Required')
  N_('Admin::UserProfileMaster|Required description')
  N_('Admin::UserProfileMaster|Sort order')
  N_('Admin::UserProfileMaster|Sort order description')
  N_('Admin::UserProfileMaster|Option values')
  N_('Admin::UserProfileMaster|Option values description|text_field')
  N_('Admin::UserProfileMaster|Option values description|number_and_hyphen_only')
  N_('Admin::UserProfileMaster|Option values description|rich_text')
  N_('Admin::UserProfileMaster|Option values description|radio')
  N_('Admin::UserProfileMaster|Option values description|year_select')
  N_('Admin::UserProfileMaster|Option values description|select')
  N_('Admin::UserProfileMaster|Option values description|appendable_select')
  N_('Admin::UserProfileMaster|Option values description|check_box')
  N_('Admin::UserProfileMaster|Option values description|prefecture_select')
  N_('Admin::UserProfileMaster|Option values description|datepicker')
  N_('Admin::UserProfileMaster|Description')
  N_('Admin::UserProfileMaster|Description description')

  def topic_title
    name
  end
end
