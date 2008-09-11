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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::ApplicationController, '#valid_file' do
  describe 'ファイルがnil又は空の場合' do
    before do
      @file = nil
      controller.send(:valid_file?, @file)
    end
    it { flash[:error].should_not be_nil }
  end
  describe 'ファイルサイズが0の場合' do
    before do
      @file = mock_csv_file(:size => 0)
      controller.send(:valid_file?, @file)
    end
    it { flash[:error].should_not be_nil }
  end
  describe 'ファイルサイズの指定が無い場合' do
    describe 'ファイルサイズが1MBを超える場合' do
      before do
        @file = mock_csv_file(:size => 1.megabyte + 1)
        controller.send(:valid_file?, @file)
      end
      it { flash[:error].should_not be_nil }
    end
  end
  describe 'ファイルサイズが100K指定された場合' do
    describe 'ファイルサイズが100Kの場合' do
      before do
        @file = mock_csv_file(:size => 100.kilobyte)
        controller.send(:valid_file?, @file, :max_size => 100.kilobyte)
      end
      it { flash[:error].should be_nil }
    end
    describe 'ファイルサイズが100Kを超える場合' do
      before do
        @file = mock_csv_file(:size => 100.kilobyte + 1)
        controller.send(:valid_file?, @file, :max_size => 100.kilobyte)
      end
      it { flash[:error].should_not be_nil }
    end
  end
  describe 'ファイルのContent-typeに制限をかけない場合' do
    describe 'ファイルのContent-typeがcsv以外の場合' do
      before do
        @file = mock_csv_file(:content_type => 'image/jpeg')
        controller.send(:valid_file?, @file)
      end
      it { flash[:error].should be_nil }
    end
  end
  describe 'ファイルのContent-typeをcsvファイルのみに制限をかける場合' do
    before do
      @content_types = ['text/csv', 'application/x-csv']
    end
    describe 'ファイルのContent-typeがcsv以外の場合' do
      before do
        file = mock_csv_file(:content_type => 'image/jpeg')
        controller.send(:valid_file?, file, :content_types => @content_types)
      end
      it { flash[:error].should_not be_nil }
    end
    describe 'ファイルのContent-typeがcsvの場合' do
      it "application/x-csvを渡した時、tureを返すこと" do
        controller.send(:valid_file?, mock_csv_file(:content_type => 'application/x-csv'), :content_types => @content_types).should be_true
      end
      it "text/csvを渡した時、trueを返すこと" do
        controller.send(:valid_file?, mock_csv_file(:content_type => 'text/csv'), :content_types => @content_types).should be_true
      end
    end
  end
end

def mock_csv_file(options = {})
  file = mock(ActionController::UploadedStringIO)
  size = options[:size] ? options[:size] : 1.kilobyte
  file.stub!(:size).and_return(size)
  content_type = options[:content_type] ? options[:content_type] : 'text/csv'
  file.stub!(:content_type).and_return(content_type)
  file
end
