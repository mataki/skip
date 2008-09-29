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

class ActionController::Base
  filter_parameter_logging :password
  before_filter :sso

  # ファイルアップロード時の共通チェック
  def valid_upload_file? file, max_size = 209715200
    file.is_a?(ActionController::UploadedFile) && file.size > 0 && file.size < max_size
  end

  # 複数ファイルアップロード時の共通チェック
  def valid_upload_files? files, max_size = 209715200
    files.each do |key, file|
      return false unless valid_upload_file?(file, max_size)
    end
    return true
  end

  def verify_extension? file_name, content_type
    !['html','htm','js'].any?{|extension| extension == file_name.split('.').last } &&
      !['text/html','application/x-javascript'].any?{|content| content == content_type }
  end

  private
  def sso
    if INITIAL_SETTINGS['login_mode'] == "rp" and !INITIAL_SETTINGS['fixed_op_url'].blank?
      unless logged_in?
        redirect_to :controller => '/platform', :action => :login, :openid_url => INITIAL_SETTINGS['fixed_op_url'], :return_to => URI.encode(request.url)
        return false
      end
      true
    end
  end
end
