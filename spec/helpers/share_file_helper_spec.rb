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

require File.dirname(__FILE__) + '/../spec_helper'

describe ShareFileHelper, '#file_size_with_unit' do
  before do
    @share_file = stub_model(ShareFile)
  end
  describe 'ファイルが存在しない場合' do
    before do
      @share_file.should_receive(:file_size).and_return(-1)
    end
    it '不明を返すこと' do
      helper.file_size_with_unit(@share_file).should == '不明'
    end
  end
  describe 'ファイルが存在する場合' do
    describe 'ファイルサイズが1メガバイト以上の場合' do
      before do
        @size = 1.megabyte
        @share_file.should_receive(:file_size).and_return(@size)
      end
      it 'メガバイト表示が返ること' do
        helper.file_size_with_unit(@share_file).should == "#{@size/1.megabyte}Mbyte"
      end
    end
    describe 'ファイルサイズが1メガバイト未満の場合' do
      describe 'ファイルサイズが1キロバイト以上の場合' do
        it 'キロバイト表示が返ること' do
          size = 1.kilobyte
          @share_file.should_receive(:file_size).and_return(size)
          helper.file_size_with_unit(@share_file).should == "#{size/1.kilobyte}Kbyte"
        end
      end
      describe 'ファイルサイズが1キロバイト未満の場合' do
        before do
          @size = 1.kilobyte - 1
        end
        it 'バイト表示が返ること' do
          @share_file.should_receive(:file_size).and_return(@size)
          helper.file_size_with_unit(@share_file).should == "#{@size}byte"
        end
      end
    end
  end
end
