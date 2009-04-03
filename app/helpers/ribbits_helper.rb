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

module RibbitsHelper
  def ribbit_menu_items(current_action)
    @@menu = [{:name => _("messages"), :menu => "message", :url => { :action => "messages"}},
              {:name => _("Call history"), :menu => "call_history", :url => { :action => "call_history" }},
              {:name => _("edit"), :menu => "edit", :url => { :action => "edit"}}]
    get_menu_items(@@menu, current_action, "message")
  end
end
