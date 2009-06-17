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

module ShareFileHelper

  def show_private_value share_file
    (share_file.owner_symbol.split(":").first == "uid") ? _("Owner Only") : _("Members Only")
  end

  def generate_new_upload_menu owner_symbol, owner_name
    url = url_for :controller =>"share_file", :action => "new", :owner_symbol => owner_symbol, :owner_name => owner_name
    dummy_link_to _('New Upload'), :onclick => "#{open_sub_window_script url}"

  end

  def generate_file_menu(share_file, owner_name = "")
    output = ""
    url = url_for :controller => "share_file", :action => "edit", :id => share_file.id, :owner_name => owner_name
    output << dummy_link_to(_('[Edit]'), :onclick => "#{open_sub_window_script url}")
    output << link_to(_('[Delete]'), { :controller=>'share_file', :action=>'destroy', :id=>share_file.id }, :confirm => _('Are you sure to delete?'), :method => :post)
  end

  def generate_manager_menu share_file
    output = ""
    output << link_to(_('[Get download history in CSV]'), { :controller => "share_file", :action => "download_history_as_csv", :id => share_file.id }, :method => :post)
    output << "<a href=\"#\" id=\"clear_download_history_link_#{share_file.id}\" class=\"clear_download_history_link\">" + _('[Clear download history]') + "</a>"
    output
  end

private
  def open_sub_window_script url
    "sub_window = window.open('#{url}', 'subwindow', 'width=550,height=400,resizable=yes,scrollbars=yes');sub_window.focus();"
  end
end
