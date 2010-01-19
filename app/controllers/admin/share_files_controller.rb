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

class Admin::ShareFilesController < Admin::ApplicationController
  include Admin::AdminModule::AdminRootModule

  def download
    share_file = Admin::ShareFile.find(params[:id])
    send_file(share_file.full_path, :filename => share_file.file_name, :type => share_file.content_type || Types::ContentType::DEFAULT_CONTENT_TYPE , :stream => false, :disposition => 'attachment')
  end
end
