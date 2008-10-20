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

describe ShareFile do
fixtures :share_files
  def test_owner_symbol_type
    @a_share_file.owner_symbol = 'uid:hoge'
    assert_equal 'user', @a_share_file.owner_symbol_type
    @a_share_file.owner_symbol = 'gid:hoge'
    assert_equal 'group', @a_share_file.owner_symbol_type
  end

  def test_owner_symbol_id
    @a_share_file.owner_symbol = 'uid:hoge'
    assert_equal 'hoge', @a_share_file.owner_symbol_id
  end

  def test_after_save
    @a_share_file.category = SkipFaker.comma_tags :qt => 3
    @a_share_file.save
    assert_equal @a_share_file.share_file_tags.size, 3
  end
end

describe ShareFile, '#full_path' do
  before do
    @share_file_path = 'temp'
    ENV.stub!('[]').with('SHARE_FILE_PATH').and_return(@share_file_path)
    FileUtils.stub!(:mkdir_p)
  end
  describe 'ユーザ所有の共有ファイルの場合' do
    before do
      symbol_type = 'uid'
      @symbol_id = '111111'
      @file_name = 'sample.csv'
      @share_file = create_share_file(:file_name => @file_name, :owner_symbol => "#{symbol_type}:#{@symbol_id}")
    end
    it 'full_pathが取得できること' do
      @share_file.full_path.should == File.join(@share_file_path, 'user', @symbol_id, @file_name)
    end
  end
end

describe ShareFile, '#validate_on_create' do
  before do
    @share_file = ShareFile.new
  end
  describe 'ファイルが指定されていない場合' do
    it 'valid_presence_of_fileのみ呼ばれること' do
      @share_file.should_receive(:valid_presence_of_file).and_return(false)
      @share_file.should_not_receive(:valid_extension_of_file)
      @share_file.should_not_receive(:valid_size_of_file)
      @share_file.should_not_receive(:valid_max_size_per_owner_of_file)
      @share_file.should_not_receive(:valid_max_size_of_system_of_file)
      @share_file.validate_on_create
    end
  end
  describe 'ファイルが指定されている場合' do
    it 'fileに関するすべての検証メソッドが呼ばれること' do
      @share_file.should_receive(:valid_presence_of_file).and_return(true)
      @share_file.should_receive(:valid_extension_of_file)
      @share_file.should_receive(:valid_size_of_file)
      @share_file.should_receive(:valid_max_size_per_owner_of_file)
      @share_file.should_receive(:valid_max_size_of_system_of_file)
      @share_file.validate_on_create
    end
  end
end

describe ShareFile, '#after_destroy' do
  before do
    @share_file = create_share_file
    File.stub!(:delete)
  end
  describe '対象ファイルが存在する場合' do
    before do
      @full_path = 'full_path'
      @share_file.stub!(:full_path).and_return(@full_path)
    end
    it 'ファイル削除が呼ばれること' do
      File.should_receive(:delete).with(@full_path)
      @share_file.after_destroy
    end
  end
  describe '対象ファイルが存在しない場合' do
    before do
      File.should_receive(:delete).and_raise(Errno::ENOENT)
    end
    it '例外を送出しないこと' do
      lambda do
        @share_file.after_destroy
      end.should_not raise_error
    end
  end
end

describe ShareFile, '#owner_symbol_name' do
  before do
    @share_file = ShareFile.new
  end
  describe 'owner_symbolに一致するオーナー(ユーザ、グループ等)が存在する場合' do
    before do
      @user_name = 'とあるゆーざー'
      @user = stub_model(User, :name => @user_name)
      Symbol.should_receive(:get_item_by_symbol).and_return(@user)
    end
    it 'オーナー名が返却されること' do
      @share_file.owner_symbol_name.should == @user_name
    end
  end
  describe 'owner_symbolに一致するオーナー(ユーザ、グループ等)が存在しない場合' do
    before do
      Symbol.should_receive(:get_item_by_symbol).and_return(nil)
    end
    it '空文字が返却されること' do
      @share_file.owner_symbol_name.should == ''
    end
  end
end

describe ShareFile, ".total_share_file_size" do
  before do
    Dir.should_receive(:glob).and_return(["a"])
    file = mock('file')
    file.stub!(:size).and_return(100)
    File.should_receive(:stat).with('a').and_return(file)
  end
  it "ファイルの合計サイズを返す" do
    ShareFile.total_share_file_size("uid:hoge").should == 100
  end
end

# privateメソッドのspec
private
def create_share_file options = {}
  share_file = ShareFile.new({
    :file_name => 'sample.csv',
    :content_type => 'text/csv',
    :date => Time.now,
    :user_id => 1,
    :owner_symbol => 'uid:111111'
  }.merge(options))
  share_file.save
  share_file
end
