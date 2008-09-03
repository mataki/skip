# SKIP（Social Knowledge & Innovation Platform）
# Copyright (C) 2008  TIS Inc.
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

class ImageController < ApplicationController

  def show
    content, user_id, file_path = params[:path]
    unless valid_params_and_authorize? content, user_id, file_path
      render :nothing => true
      return false 
    end
    open(File.join(ENV['IMAGE_PATH'], params[:path]), "rb") do |f|
      send_data(f.read, :filename=>params[:path], :disposition=>"inline")
    end
  rescue
    render :text=>'見つかりません!！'
  end

  private
  def valid_params_and_authorize? content, user_id, file_path 
    # ver.0.9時点では、pathは、"/board_entries/#{user_id}/#{entry_id}_ファイル名"で構成
    if content == 'board_entries' && /\d*/ =~ user_id
      if entry_id = file_path.scan(/^(\d*)_[^\/]*\.\w*/)
        return BoardEntry.find(entry_id.to_s).entry_publications.any? do |publication|
          [session[:user_symbol], Symbol::SYSTEM_ALL_USER].include? publication.symbol
        end
      end
    end
    return false
  end
end
