# SKIP(Social Knowledge & Innovation Platform)
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
    open(File.join(ENV['IMAGE_PATH'], params[:path]), "rb") do |f|
      send_data(f.read, :filename=>params[:path], :disposition=>"inline")
    end
  rescue
    render :text=>'見つかりません!！'
  end

end
