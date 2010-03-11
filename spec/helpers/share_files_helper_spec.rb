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

require File.dirname(__FILE__) + '/../spec_helper'

describe ShareFilesHelper, '#file_link_url' do
  describe '第一引数がShareFileのインスタンスの場合' do
    before do
      @share_file = stub_model(ShareFile, :owner_symbol => 'uid:foo', :file_name => 'bar.jpg')
    end
    it 'share_file_urlが正しいパラメタで呼ばれること' do
      helper.should_receive(:share_file_url).with(:controller_name => 'user', :symbol_id => 'foo', :file_name => 'bar.jpg')
      helper.file_link_url(@share_file)
    end
  end
  describe '第一引数がHashの場合' do
    before do
      @share_file_hash = {:owner_symbol => 'uid:foo', :file_name => 'bar.jpg'}
    end
    it 'share_file_urlが正しいパラメタで呼ばれること' do
      helper.should_receive(:share_file_url).with(:controller_name => 'user', :symbol_id => 'foo', :file_name => 'bar.jpg')
      helper.file_link_url(@share_file_hash)
    end
  end
end

