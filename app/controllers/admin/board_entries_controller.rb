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

class Admin::BoardEntriesController < Admin::ApplicationController
  include Admin::AdminModule::AdminRootModule

  # FIXME [#855][#907]Rails2.3.2のバグでcounter_cacheと:dependent => destoryを併用すると常にStaleObjectErrorとなる
  # SKIPではBoardEntryとBoardEntryCommentの関係が該当する。Rails2.3.5でFixされたら以下を修正すること
  def destroy
    @board_entry = BoardEntry.find(params[:id])
    @board_entry.board_entry_comments.destroy_all
    @board_entry.reload
    @board_entry.destroy

    respond_to do |format|
      flash[:notice] = _("%{model} was successfully deleted.") % {:model => _('board entry')}
      format.html { redirect_to(index_url) }
      format.xml  { head :ok }
    end
  end

  def close
    @board_entry = BoardEntry.find(params[:id])
    @board_entry.be_close!

    respond_to do |format|
      flash[:notice] = _("%{model} was successfully updated.") % {:model => _('board entry')}
      format.html { redirect_to(index_url) }
    end
  end
end
