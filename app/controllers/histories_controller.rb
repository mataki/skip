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

class HistoriesController < ApplicationController
  layout 'wiki'
  before_filter :require_wiki_enabled

  def index
    @current_page = Page.find_by_title(params[:wiki_id])
    @histories = @current_page.histories
  end

  def show
    @current_page = Page.find_by_title(params[:wiki_id])
    @history = @current_page.histories.detect{|h| h.id == params[:id].to_i }
  end

  def diff
    @current_page = Page.find_by_title(params[:wiki_id], :include => :histories)
    @diffs = @current_page.diff(params[:from], params[:to])
  end
end

