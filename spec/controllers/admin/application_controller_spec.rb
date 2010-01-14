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

describe Admin::ApplicationController, '#require_admin' do
  describe '管理者じゃない場合' do
    before do
      @user = mock_model(User)
      @user.stub!(:admin).and_return(false)
      @user.stub!(:active?).and_return(true)
      controller.should_receive(:current_user).and_return(@user)
      @url = '/'
      controller.stub!(:root_url).and_return(@url)
      controller.stub!(:redirect_to).with(@url)
    end
    it 'mypageへのリダイレクト処理が呼ばれること' do
      controller.should_receive(:redirect_to).with(@url)
      controller.require_admin
    end
    it 'falseが返却されること' do
      controller.require_admin.should be_false
    end
  end
end

describe Admin::ApplicationController, '#valid_file?' do
  describe 'ファイルがnil又は空の場合' do
    before do
      @file = nil
      controller.send(:valid_file?, @file)
    end
    it { flash[:error].should_not be_nil }
  end
  describe 'ファイルサイズが0の場合' do
    before do
      @file = mock_file(:size => 0)
      controller.send(:valid_file?, @file)
    end
    it { flash[:error].should_not be_nil }
  end
  describe 'ファイルサイズの指定が無い場合' do
    describe 'ファイルサイズが1MBを超える場合' do
      before do
        @file = mock_file(:size => 1.megabyte + 1)
        controller.send(:valid_file?, @file)
      end
      it { flash[:error].should_not be_nil }
    end
  end
  describe 'ファイルサイズが100K指定された場合' do
    describe 'ファイルサイズが100Kの場合' do
      before do
        @file = mock_file(:size => 100.kilobyte)
        controller.send(:valid_file?, @file, :max_size => 100.kilobyte)
      end
      it { flash[:error].should be_nil }
    end
    describe 'ファイルサイズが100Kを超える場合' do
      before do
        @file = mock_file(:size => 100.kilobyte + 1)
        controller.send(:valid_file?, @file, :max_size => 100.kilobyte)
      end
      it { flash[:error].should_not be_nil }
    end
  end
  describe 'ファイルのContent-typeに制限をかけない場合' do
    describe 'ファイルのContent-typeがcsv以外の場合' do
      before do
        @file = mock_file(:content_type => 'image/jpeg')
        controller.send(:valid_file?, @file)
      end
      it { flash[:error].should be_nil }
    end
  end
  describe 'ファイルのContent-typeをcsvファイル及びplaintextのみに制限をかける場合' do
    before do
      @content_types = ['text/csv', 'application/x-csv']
    end
    describe 'ファイルのContent-typeがcsv以外の場合' do
      before do
        file = mock_file(:content_type => 'image/jpeg')
        controller.send(:valid_file?, file, :content_types => @content_types)
      end
      it { flash[:error].should_not be_nil }
    end
    describe 'ファイルのContent-typeがtext/plainの場合' do
      before do
        file = mock_file(:content_type => 'text/plain')
        controller.send(:valid_file?, file, :content_types => @content_types)
      end
      it { flash[:error].should be_true }
    end
    describe 'ファイルのContent-typeがcsvの場合' do
      it "application/x-csvを渡した時、tureを返すこと" do
        controller.send(:valid_file?, mock_file(:content_type => 'application/x-csv'), :content_types => @content_types).should be_true
      end
      it "text/csvを渡した時、trueを返すこと" do
        controller.send(:valid_file?, mock_file(:content_type => 'text/csv'), :content_types => @content_types).should be_true
      end
    end
  end

  describe "text/plainでファイルフォーマットが間違っている場合" do
    before do
      file = mock_file(:content_type => 'text/plain')
      file.stub!(:read).and_return("hogemoge")
      controller.send(:valid_file?, file, :content_types => @content_types)
    end
    it { flash[:error].should_not be_nil }
  end

  describe "拡張子の制限がjpgだった場合" do
    describe "拡張子がjpgのファイルがわたってきた場合" do
      it "trueを返すこと" do
        controller.send(:valid_file?, mock_file(:original_filename => "sample.jpg"), :extension => "jpg").should be_true
      end
    end
    describe "拡張子がJPGのファイルがわたってきた場合" do
      it "trueを返すこと" do
        controller.send(:valid_file?, mock_file(:original_filename => "sample.JPG"), :extension => "jpg").should be_true
      end
    end
    describe "拡張子がpngのファイルがわたってきた場合" do
      it "falseを返すこと" do
        controller.send(:valid_file?, mock_file(:original_filename => "sample.png"), :extension => "jpg").should be_false
      end
    end
  end
end

def mock_file(options = {})
  file = mock(ActionController::UploadedStringIO)
  size = options[:size] ? options[:size] : 1.kilobyte
  file.stub!(:size).and_return(size)
  content_type = options[:content_type] ? options[:content_type] : 'text/csv'
  file.stub!(:content_type).and_return(content_type)
  file.stub!(:original_filename).and_return(options[:original_filename])
  file
end
