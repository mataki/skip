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

describe MoveAttachmentImage, '.new_share_file' do
  describe '移行対象の画像が添付された記事が存在する場合' do
    before do
      @board_entry = stub_model(BoardEntry, :symbol => 'symbol', :publication_type => 'publication_type', :publication_symbols_value => 'publication_symbols_value')
      MoveAttachmentImage.should_receive(:image_attached_entry).and_return(@board_entry)
      @share_file = MoveAttachmentImage.new_share_file(99, '99_image_file.png')
    end
    it '共有ファイルの値が設定されること' do
      @share_file.file_name.should == 'image_file.png'
      @share_file.owner_symbol.should == 'symbol'
      @share_file.date.should_not be_nil
      @share_file.user_id.should == 99
      @share_file.content_type.should == 'image/png'
      @share_file.publication_type.should == 'publication_type'
      @share_file.publication_symbols_value == 'publication_symbols_value'
    end
  end
  describe '移行対象の画像が添付された記事が存在しない場合' do
    before do
      MoveAttachmentImage.should_receive(:image_attached_entry).and_return(nil)
    end
    it 'nilが返ること' do
      MoveAttachmentImage.new_share_file(99, '99_image_file.png').should be_nil
    end
  end
end

describe MoveAttachmentImage, '.share_file_name' do
  describe '対象の所有者に既に同名ファイルが登録されている場合' do
    before do
      ShareFile.should_receive(:find_by_owner_symbol_and_file_name).with('uid:owner', 'image_name.png').and_return(stub_model(ShareFile))
      ShareFile.should_receive(:find_by_owner_symbol_and_file_name).with('uid:owner', 'image_name_.png').and_return(nil)
    end
    it 'ファイル名末尾に_(アンダースコア)が付加されたファイル名が取得出来ること' do
      MoveAttachmentImage.share_file_name('uid:owner', '7_image_name.png').should == 'image_name_.png'
    end
  end
  describe '対象の所有者にまだ同名ファイルが登録されていない場合' do
    before do
      ShareFile.should_receive(:find_by_owner_symbol_and_file_name).with('uid:owner', 'image_name.png').and_return(nil)
    end
    it '共有ファイルに登録するファイル名が取得出来ること' do
      MoveAttachmentImage.share_file_name('uid:owner', '7_image_name.png').should == 'image_name.png'
    end
  end
end

describe MoveAttachmentImage, '.image_attached_entry' do
  it '画像の添付対象記事を取得しようとすること' do
    BoardEntry.should_receive(:find_by_id).with(7)
    MoveAttachmentImage.image_attached_entry('7_image_name.png')
  end
end

describe MoveAttachmentImage, '.replace_direct_link' do
  describe 'オーナーがユーザの記事本文及びコメントに添付画像への直リンクが書かれている場合' do
    before do
      @board_entry = create_entry_wrote_direct_attachment_link('uid:foo')

      BoardEntry.should_receive(:all).and_return([@board_entry])
      BoardEntry.stub!(:find_by_id).with(9).and_return(@board_entry)

      @user = stub_model(User)
      User.stub!(:find_by_uid).and_return(@user)
    end
    it '記事本文の添付画像への直リンクがデータ移行後の共有ファイルへのリンクになっていること' do
      MoveAttachmentImage.replace_direct_link
      @board_entry.contents.include?("http://localhost:3000/share_file/user/#{@user.id}/foo.png").should be_true
    end
    it 'コメント内の添付画像への直リンクがデータ移行後の共有ファイルへのリンクになっていること' do
      MoveAttachmentImage.replace_direct_link
      @board_entry.board_entry_comments[0].contents.include?("http://localhost:3000/share_file/user/#{@user.id}/foo.png").should be_true
    end
  end
  describe 'オーナーがグループの記事本文及びコメントに添付画像への直リンクが書かれている場合' do
    before do
      @board_entry = create_entry_wrote_direct_attachment_link('gid:bar')

      BoardEntry.should_receive(:all).and_return([@board_entry])
      BoardEntry.stub!(:find_by_id).with(9).and_return(@board_entry)

      @group = stub_model(Group)
      Group.stub!(:find_by_gid).and_return(@group)
    end
    it '記事本文の添付画像への直リンクがデータ移行後の共有ファイルへのリンクになっていること' do
      MoveAttachmentImage.replace_direct_link
      @board_entry.contents.include?("http://localhost:3000/share_file/group/#{@group.id}/foo.png").should be_true
    end
    it 'コメント内の添付画像への直リンクがデータ移行後の共有ファイルへのリンクになっていること' do
      MoveAttachmentImage.replace_direct_link
      @board_entry.board_entry_comments[0].contents.include?("http://localhost:3000/share_file/group/#{@group.id}/foo.png").should be_true
    end
  end

  def create_entry_wrote_direct_attachment_link symbol
    board_entry = BoardEntry.new({
      :title => 'foo',
      :contents => 'http://localhost:3000/images/board_entries%2F9%2F99_foo.png',
      :symbol => symbol,
      :date => Date.today,
      :user_id => 9,
      :last_updated => Date.today
    })
    board_entry.save!
    board_entry_comment = BoardEntryComment.new({
      :contents => 'http://localhost:3000/images/board_entries/9/99_foo.png',
      :user_id => 9,
      :board_entry_id => board_entry.id
    })
    board_entry_comment.save!
    board_entry
  end
end
