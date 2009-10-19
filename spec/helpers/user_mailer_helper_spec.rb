# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
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

describe UserMailerHelper, '#convert_plain' do
  describe '100文字未満のタグが含まれない本文の場合' do
    before do
      @entry = create_board_entry :contents => 'テスト'
    end
    it '本文がそのまま取得出来ること' do
      helper.convert_plain(@entry).should == "テスト"
    end
  end
  describe '100文字を越えるタグが含まれない本文の場合' do
    before do
      @entry = create_board_entry :contents => 'あ'*101
    end
    it '本文が100文字で切断されていること' do
      helper.convert_plain(@entry).should == 'あ'*100
    end
  end
end
