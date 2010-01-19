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

class OauthProvider < ActiveRecord::Base
  attr_protected :enable
  named_scope :enable, {:conditions => {:enable => true}}

  def setting
    @setting ||= CollaborationApp::Setting.new self.app_name
  end

  def after_save
    ActionController::Base.expire_page  '/services/skip_reflect_customized.js'
  end
end
