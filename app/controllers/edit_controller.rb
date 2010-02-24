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

class EditController < ApplicationController
  include BoardEntriesHelper

  verify :method => :post, :only => [:delete_trackback ], :redirect_to => { :action => :index }

  def delete_trackback
    @board_entry = get_entry params[:id]

    redirect_to_with_deny_auth and return unless @board_entry.user_id == session[:user_id]

    tb_entries = EntryTrackback.find_all_by_board_entry_id_and_tb_entry_id(@board_entry.id, params[:tb_entry_id])
    tb_entries.each do |tb_entry|
      tb_entry.destroy
    end

    flash[:notice] = _("Specified trackback was deleted successfully.")
    redirect_to @board_entry.get_url_hash
  end

private
  def get_entry entry_id
    @board_entry = BoardEntry.find(params[:id])
  end
end

