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
end

describe ShareFile, '.new' do
  describe 'オーナーがユーザの場合' do
    before do
      @share_file = ShareFile.new(:owner_symbol => 'uid:foo')
    end
    it '公開範囲が全体公開になっていること' do
      @share_file.publication_type.should == 'public'
    end
  end
  describe 'オーナーがグループの場合' do
    describe 'グループが存在し、デフォルトの公開範囲が全体公開の場合' do
      before do
        create_group :gid => 'vimgroup', :default_publication_type => 'public'
        @share_file = ShareFile.new(:owner_symbol => 'gid:vimgroup')
      end
      it '公開範囲が全体公開になっていること' do
        @share_file.publication_type.should == 'public'
      end
    end
    describe 'グループが存在しない場合' do
      before do
        @share_file = ShareFile.new(:owner_symbol => 'gid:vimgroup')
      end
      it '公開範囲が自分だけになっていること' do
        @share_file.publication_type.should == 'private'
      end
    end
  end
end

describe ShareFile, '#full_path' do
  before do
    @share_file_path = 'temp'
    SkipEmbedded::InitialSettings["share_file_path"] = @share_file_path
    FileUtils.stub!(:mkdir_p)
  end
  describe 'ユーザ所有の共有ファイルの場合' do
    before do
      symbol_type = 'uid'
      @symbol_id = '111111'
      @file_name = 'sample.csv'
      @share_file = create_share_file(:file_name => @file_name, :owner_symbol => "#{symbol_type}:#{@symbol_id}")
      @user = stub_model(User)
      User.stub!(:find_by_uid).with(@symbol_id).and_return(@user)
    end
    it 'full_pathが取得できること' do
      @share_file.full_path.should == File.join(@share_file_path, 'user', @user.id.to_s, @file_name)
    end
  end
end

describe ShareFile, '#validate' do
  before do
    @share_file = ShareFile.new
  end
  describe '権限チェック' do
    before do
      Tag.stub!(:validate_tags).and_return([])
    end
    describe '保存権限がある場合' do
      before do
        @share_file.should_receive(:full_accessible?).and_return(true)
      end
      it 'エラーメッセージが設定されないこと' do
        lambda do
          @share_file.validate
        end.should_not change(@share_file, :errors)
      end
    end
    describe '保存権限がない場合' do
      before do
        @share_file.should_receive(:full_accessible?).and_return(false)
        @errors = mock('errors')
        @errors.stub!(:add_to_base)
        @share_file.stub!(:errors).and_return(@errors)
      end
      it 'エラーメッセージが設定されること' do
        @share_file.errors.should_receive(:add_to_base).with('Operation inexecutable.')
        @share_file.validate
      end
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
      @share_file.should_not_receive(:valid_max_size_of_system_of_file)
      @share_file.validate_on_create
    end
  end
  describe 'ファイルが指定されている場合' do
    it 'fileに関するすべての検証メソッドが呼ばれること' do
      @share_file.should_receive(:valid_presence_of_file).and_return(true)
      @share_file.should_receive(:valid_extension_of_file)
      @share_file.should_receive(:valid_content_type_of_file)
      @share_file.should_receive(:valid_size_of_file)
      @share_file.should_receive(:valid_max_size_of_system_of_file)
      @share_file.validate_on_create
    end
  end
end

describe ShareFile, '#after_destroy' do
  before do
    @share_file = create_share_file
    ShareFile.stub!(:dir_path).and_return('dir_path')
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

describe ShareFile, '#owner_id' do
  before do
    @share_file = ShareFile.new(:owner_symbol => 'uid:hoge')
  end
  describe 'owner_symbolに対する所有者が取得できる場合' do
    before do
      @user = stub_model(User, :id => 99)
      User.should_receive(:find_by_uid).and_return(@user)
    end
    it 'idが返ること' do
      @share_file.owner_id.should == 99
    end
  end
  describe 'owner_symbolに対する所有者が取得できない場合' do
    before do
      User.should_receive(:find_by_uid).and_return(nil)
    end
    it 'owner_symbolに対する所有者が存在しないことを示す例外を送出すること' do
      # これが起きるケースはデータ不整合が起こっていると考えられる。
      lambda do
        @share_file.owner_id
      end.should raise_error(RuntimeError)
    end
  end
end

describe ShareFile, ".total_share_file_size" do
  before do
    ShareFile.stub!(:dir_path)
    Dir.should_receive(:glob).and_return(["a"])
    file = mock('file')
    file.stub!(:size).and_return(100)
    File.should_receive(:stat).with('a').and_return(file)
  end
  it "ファイルの合計サイズを返す" do
    ShareFile.total_share_file_size("uid:hoge").should == 100
  end
end

describe ShareFile, '#uncheck_authenticity?' do
  before do
    @share_file = stub_model(ShareFile)
  end
  describe 'チェックしない拡張子の場合' do
    before do
      @share_file.should_receive(:uncheck_extention?).and_return(true)
    end
    describe 'チェックしないContent-Typeの場合' do
      before do
        @share_file.should_receive(:uncheck_content_type?).and_return(true)
      end
      it 'trueを返すこと' do
        @share_file.uncheck_authenticity?.should be_true
      end
    end
    describe 'チェックするContent-Typeの場合' do
      before do
        @share_file.should_receive(:uncheck_content_type?).and_return(false)
      end
      it 'falseを返すこと' do
        @share_file.uncheck_authenticity?.should be_false
      end
    end
  end
  describe 'チェックする拡張子の場合' do
    before do
      @share_file.should_receive(:uncheck_extention?).and_return(false)
    end
    it 'falseを返すこと' do
      @share_file.uncheck_authenticity?.should be_false
    end
  end
end

describe ShareFile, '#uncheck_extention?' do
  describe 'authenticityチェックしない拡張子(uncheck.jpg)の場合' do
    before do
      @share_file = stub_model(ShareFile, :file_name => 'uncheck.jpg')
    end
    it 'trueを返すこと' do
      @share_file.send(:uncheck_extention?).should be_true
    end
  end

  describe 'authenticityチェックしない拡張子(uncheck.JPG)の場合' do
    before do
      @share_file = stub_model(ShareFile, :file_name => 'uncheck.JPG')
    end
    it 'trueを返すこと' do
      @share_file.send(:uncheck_extention?).should be_true
    end
  end

  describe 'authenticityチェックする拡張子の場合' do
    before do
      @share_file = stub_model(ShareFile, :file_name => 'uncheck.xls')
    end
    it 'falseを返すこと' do
      @share_file.send(:uncheck_extention?).should be_false
    end
  end

  describe '拡張子がなく、紛らわしいファイル名の場合' do
    before do
      @share_file = stub_model(ShareFile, :file_name => 'jpg')
    end
    it 'falseを返すこと' do
      @share_file.send(:uncheck_extention?).should be_false
    end
  end
end

describe ShareFile, '#downloadable_content_type' do
  describe 'authenticityチェックしないContent-Typeの場合' do
    before do
      @share_file = stub_model(ShareFile, :content_type => 'image/jpg')
    end
    it 'trueを返すこと' do
      @share_file.send(:uncheck_content_type?).should be_true
    end
  end
  describe 'authenticityチェックするContent-Typeの場合' do
    before do
      @share_file = stub_model(ShareFile, :content_type => 'application/csv')
    end
    it 'falseを返すこと' do
      @share_file.send(:uncheck_content_type?).should be_false
    end
  end
end

describe ShareFile, '#file_size_with_unit' do
  before do
    @share_file = stub_model(ShareFile)
  end
  describe 'ファイルが存在しない場合' do
    before do
      @share_file.should_receive(:file_size).and_return(-1)
    end
    it '不明を返すこと' do
      @share_file.file_size_with_unit.should == '不明'
    end
  end
  describe 'ファイルが存在する場合' do
    describe 'ファイルサイズが1メガバイト以上の場合' do
      before do
        @size = 1.megabyte
        @share_file.should_receive(:file_size).and_return(@size)
      end
      it 'メガバイト表示が返ること' do
        @share_file.file_size_with_unit.should == "#{@size/1.megabyte}Mbyte"
      end
    end
    describe 'ファイルサイズが1メガバイト未満の場合' do
      describe 'ファイルサイズが1キロバイト以上の場合' do
        it 'キロバイト表示が返ること' do
          size = 1.kilobyte
          @share_file.should_receive(:file_size).and_return(size)
          @share_file.file_size_with_unit.should == "#{size/1.kilobyte}Kbyte"
        end
      end
      describe 'ファイルサイズが1キロバイト未満の場合' do
        before do
          @size = 1.kilobyte - 1
        end
        it 'バイト表示が返ること' do
          @share_file.should_receive(:file_size).and_return(@size)
          @share_file.file_size_with_unit.should == "#{@size}byte"
        end
      end
    end
  end
end

# privateメソッドのspec
describe ShareFile, '#owner_is_user?' do
  describe '所有者がユーザの場合' do
    before do
      @share_file = ShareFile.new(:owner_symbol => 'uid:owner')
    end
    it 'trueを返すこと' do
      @share_file.send(:owner_is_user?).should be_true
    end
  end
  describe '所有者がユーザ以外の場合' do
    before do
      @share_file = ShareFile.new(:owner_symbol => 'zid:owner')
    end
    it 'falseを返すこと' do
      @share_file.send(:owner_is_user?).should be_false
    end
  end
end

describe ShareFile, '#owner_is_group?' do
  describe '所有者がグループの場合' do
    before do
      @share_file = ShareFile.new(:owner_symbol => 'gid:owner')
    end
    it 'trueを返すこと' do
      @share_file.send(:owner_is_group?).should be_true
    end
  end
  describe '所有者がグループ以外の場合' do
    before do
      @share_file = ShareFile.new(:owner_symbol => 'zid:owner')
    end
    it 'falseを返すこと' do
      @share_file.send(:owner_is_group?).should be_false
    end
  end
end

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
