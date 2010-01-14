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

describe EditHelper, '#share_file_url' do
  describe 'uidの場合' do
    it 'ユーザの共有ファイル一覧へのurlとなること' do
      helper.send(:share_files_url, 'uid:foo').should == '/user/foo/share_file?format=js'
    end
  end
  describe 'gidの場合' do
    it 'グループの共有ファイル一覧へのurlとなること' do
      helper.send(:share_files_url, 'gid:bar').should == '/group/bar/share_file?format=js'
    end
  end
  describe 'uid, gid以外の場合' do
    it 'ArgumentErrorが発生すること' do
      lambda do
        helper.send(:share_files_url, 'zid:foo')
      end.should raise_error(ArgumentError)
    end
  end
end
