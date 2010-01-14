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

describe SkipUtil, '.full_error_messages' do
  describe '引数が配列以外の場合' do
    it '空配列が返ること' do
      SkipUtil.full_error_messages(nil).should == []
    end
  end
  describe '引数が配列の場合' do
    before do
      @valid_record = mock_model(ActiveRecord::Base, :valid? => true)
      @invalid_record = mock_model(ActiveRecord::Base, :valid? => false, :errors => mock('errors', :full_messages => ['エラー']))
    end
    describe 'サイズの2の配列でエラーがない場合' do
      it '空配列が返ること' do
        SkipUtil.full_error_messages([@valid_record, @valid_record]).should == []
      end
    end
    describe 'サイズの2の配列で1つだけエラーの場合' do
      before do
        @records = [@valid_record, @invalid_record]
      end
      it 'サイズ1の配列が返ること' do
        SkipUtil.full_error_messages(@records).size.should == 1
      end
      it 'エラーが設定されていること' do
        SkipUtil.full_error_messages(@records)[0].should == 'エラー'
        SkipUtil.full_error_messages(@records)[1].should be_nil
      end
    end
    describe 'サイズの2の配列で2つともエラーの場合' do
      before do
        @records = [@invalid_record, @invalid_record]
      end
      it 'サイズ2の配列が返ること' do
        SkipUtil.full_error_messages(@records).size.should == 2
      end
      it 'エラーが設定されていること' do
        SkipUtil.full_error_messages(@records)[0].should == 'エラー'
        SkipUtil.full_error_messages(@records)[1].should == 'エラー'
      end
    end
  end
end

