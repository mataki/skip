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

class ValidateFileClass
  include ValidationsFile

  attr_accessor :file
end

describe ValidationsFile do
  before do
    @vf = mock_model_class
    @muf = mock_uploaed_file
  end
  describe "#valid_presence_of_file" do
    describe "ファイルが設定されている場合" do
      it "trueを返すこと" do
        @vf.valid_presence_of_file(@muf).should be_true
      end
    end
    describe "ファイルが設定されていない場合" do
      it "falseを返ること" do
        @vf.valid_presence_of_file("string").should be_false
      end
      it "エラーが追加されること" do
        @vf.errors.should_receive(:add_to_base).with("ファイルが指定されていません。")
        @vf.valid_presence_of_file("string")
      end
    end
  end

  describe "#valid_extension_of_file" do
    describe "ファイルの形式が不正な場合" do
      it "エラーが追加されること" do
        @vf.errors.should_receive(:add_to_base).with("この形式のファイルは、アップロードできません。")
        @vf.should_receive(:verify_extension?).and_return(false)
        @vf.send!(:valid_extension_of_file, @muf)
      end
    end
  end

  describe "#valid_size_of_file" do
    describe "ファイルサイズが0の場合" do
      it "エラーが追加されること" do
        @muf.stub!(:size).and_return(0)
        @vf.errors.should_receive(:add_to_base).with('存在しないもしくはサイズ０のファイルはアップロードできません。')
        @vf.valid_size_of_file(@muf)
      end
    end
    describe "ファイルサイズが最大値を超えている場合" do
      it "エラーが追加されること" do
        @muf.stub!(:size).and_return(SkipEmbedded::InitialSettings['max_share_file_size'].to_i + 100)
        @vf.errors.should_receive(:add_to_base).with("#{SkipEmbedded::InitialSettings['max_share_file_size'].to_i/1.megabyte}Mバイト以上のファイルはアップロードできません。")
        @vf.valid_size_of_file(@muf)
      end
    end
  end

  describe "#valid_max_size_per_owner_of_file" do
    describe "ファイルサイズがオーナーの最大許可容量を超えている場合" do
      it "エラーが追加されること" do
        @muf.stub!(:size).and_return(101)
        owner_symbol = "git:hoge"
        ValidationsFile::FileSizeCounter.should_receive(:per_owner).with(owner_symbol).and_return(SkipEmbedded::InitialSettings['max_share_file_size_per_owner'].to_i - 100)
        @vf.errors.should_receive(:add_to_base).with("共有ファイル保存領域の利用容量が最大値を越えてしまうためアップロードできません。")
        @vf.valid_max_size_per_owner_of_file(@muf, owner_symbol)
      end
    end
  end

  describe "#valid_max_size_of_system_of_file" do
    describe "ファイルサイズがオーナーの最大許可容量を超えている場合" do
      it "エラーが追加されること" do
        @muf.stub!(:size).and_return(101)
        ValidationsFile::FileSizeCounter.should_receive(:per_system).and_return(SkipEmbedded::InitialSettings['max_share_file_size_of_system'].to_i - 100)
        @vf.errors.should_receive(:add_to_base).with('システム全体における共有ファイル保存領域の利用容量が最大値を越えてしまうためアップロードできません。')
        @vf.valid_max_size_of_system_of_file(@muf)
      end
    end
  end

  describe '#valid_content_type_of_file' do
    describe 'ファイルの拡張子に対するContentTypeが不正な場合' do
      before do
        @muf.stub!(:original_filename).and_return('image.jpg')
        @muf.stub!(:content_type).and_return('image/gif')
        @vf.errors.should_receive(:add_to_base).with('この形式のファイルは、アップロードできません。')
        @vf.valid_content_type_of_file(@muf)
      end
    end
    describe '拡張子がjpgの場合' do
      before do
        @muf.stub!(:original_filename).and_return('image.jpg')
      end
      describe 'content_typeがimage/jpgの場合' do
        before do
          @muf.stub!(:content_type).and_return('image/jpg')
        end
        it { @vf.valid_content_type_of_file(@muf).should be_true }
      end
      describe 'content_typeがimage/jpegの場合' do
        before do
          @muf.stub!(:content_type).and_return('image/jpeg')
        end
        it { @vf.valid_content_type_of_file(@muf).should be_true }
      end
      describe 'content_typeがimage/pjpeg(プログレッシブ画像)の場合' do
        before do
          @muf.stub!(:content_type).and_return('image/pjpeg')
        end
        it { @vf.valid_content_type_of_file(@muf).should be_true }
      end
    end
    describe '拡張子がjpegの場合' do
      before do
        @muf.stub!(:original_filename).and_return('image.jpeg')
      end
      describe 'content_typeがimage/jpgの場合' do
        before do
          @muf.stub!(:content_type).and_return('image/jpg')
        end
        it { @vf.valid_content_type_of_file(@muf).should be_true }
      end
      describe 'content_typeがimage/jpegの場合' do
        before do
          @muf.stub!(:content_type).and_return('image/jpeg')
        end
        it { @vf.valid_content_type_of_file(@muf).should be_true }
      end
      describe 'content_typeがimage/pjpeg(プログレッシブ画像)の場合' do
        before do
          @muf.stub!(:content_type).and_return('image/pjpeg')
        end
        it { @vf.valid_content_type_of_file(@muf).should be_true }
      end
    end
    describe '拡張子がpngの場合' do
      before do
        @muf.stub!(:original_filename).and_return('image.png')
      end
      describe 'content_typeがimage/pngの場合' do
        before do
          @muf.stub!(:content_type).and_return('image/png')
        end
        it { @vf.valid_content_type_of_file(@muf).should be_true }
      end
      describe 'content_typeがimage/x-pngの場合' do
        before do
          @muf.stub!(:content_type).and_return('image/x-png')
        end
        it { @vf.valid_content_type_of_file(@muf).should be_true }
      end
    end
    describe '拡張子がgifの場合' do
      before do
        @muf.stub!(:original_filename).and_return('image.gif')
      end
      describe 'content_typeがimage/gifの場合' do
        before do
          @muf.stub!(:content_type).and_return('image/gif')
        end
        it { @vf.valid_content_type_of_file(@muf).should be_true }
      end
    end
    describe '拡張子がbmpの場合' do
      before do
        @muf.stub!(:original_filename).and_return('image.bmp')
      end
      describe 'content_typeがimage/bmpの場合' do
        before do
          @muf.stub!(:content_type).and_return('image/bmp')
        end
        it { @vf.valid_content_type_of_file(@muf).should be_true }
      end
    end
  end

  describe '#verify_extension?' do
    before do
      @disallow_extension = 'disallow_extension'
      @vf.should_receive(:disallow_extensions).and_return([@disallow_extension])
    end
    describe '許可されない拡張子の場合' do
      it 'falseが返ること' do
        @vf.send(:verify_extension?, "file.#{@disallow_extension}", 'content_type').should be_false
      end
    end
    describe '許可される拡張子の場合' do
      before do
        @allow_extension = 'allow_extension'
        @disallow_content_type = 'disallow_content_type'
        @vf.should_receive(:disallow_content_types).and_return([@disallow_content_type])
      end
      describe '許可されるcontent_typeの場合' do
        before do
          @allow_content_type = 'allow_content_type'
        end
        it 'trueが返ること' do
          @vf.send(:verify_extension?, "file.#{@allow_extension}", @allow_content_type).should be_true
        end
      end
      describe '許可されないcontent_typeの場合' do
        it 'falseが返ること' do
          @vf.send(:verify_extension?, "file.#{@allow_extension}", @disallow_content_type).should be_false
        end
      end
    end
  end

  describe '#disallow_content_types' do
    it 'text/htmlが含まれること' do
      @vf.send!(:disallow_content_types).include?('text/html').should be_true
    end
    it 'application/x-javascriptが含まれること' do
      @vf.send!(:disallow_content_types).include?('application/x-javascript').should be_true
    end
    it 'image/bmpが含まれること' do
      @vf.send!(:disallow_content_types).include?('image/bmp').should be_true
    end
  end

  describe '#disallow_extensions' do
    it 'htmlが含まれること' do
      @vf.send!(:disallow_extensions).include?('html').should be_true
    end
    it 'htmが含まれること' do
      @vf.send!(:disallow_extensions).include?('htm').should be_true
    end
    it 'jsが含まれること' do
      @vf.send!(:disallow_extensions).include?('js').should be_true
    end
    it 'bmpが含まれること' do
      @vf.send!(:disallow_extensions).include?('bmp').should be_true
    end
  end

  def mock_model_class
    errors = mock('errors')
    errors.stub!(:add_to_base)

    vf = ValidateFileClass.new
    vf.stub!(:errors).and_return(errors)
    vf
  end
end

describe ValidationsFile::FileSizeCounter do
  describe ".per_owner" do
    before do
      ShareFile.should_receive(:total_share_file_size).and_return(100)
    end
    it "ファイルサイズを返す" do
      ValidationsFile::FileSizeCounter.per_owner(@owner_symbol).should == 100
    end
  end
  describe ".per_system" do
    before do
      Dir.should_receive(:glob).with("#{SkipEmbedded::InitialSettings['share_file_path']}/**/*").and_return(["a", "a"])
      file = mock('file')
      file.stub!(:size).and_return(100)
      File.should_receive(:stat).with('a').at_least(:once).and_return(file)
    end
    it "ファイルサイズを返す" do
      ValidationsFile::FileSizeCounter.per_system.should == 200
    end
  end
end
