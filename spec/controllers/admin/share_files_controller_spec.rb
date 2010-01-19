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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::ShareFilesController, 'GET /download' do
  before do
    admin_login
    @share_file = stub_model(Admin::ShareFile)
    @share_file.stub!(:full_path).and_return('/full_path')
    Admin::ShareFile.should_receive(:find).and_return(@share_file)
  end
  it '取得した共有ファイルの実体ファイルの送信処理が行われること' do
    controller.should_receive(:send_file).with(@share_file.full_path, {:filename => @share_file.file_name,
                                               :type => @share_file.content_type, :stream => false, :disposition => 'attachment'})
    get :download
  end
end
