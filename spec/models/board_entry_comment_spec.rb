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

describe BoardEntryComment, "は何も定義されていない場合Validationエラーが発生する" do
  before(:each) do
    @board_entry_comment = BoardEntryComment.new
  end

  it { @board_entry_comment.should_not be_valid }
  it { @board_entry_comment.should have(1).errors_on(:board_entry_id) }
  it { @board_entry_comment.should have(1).errors_on(:contents) }
  it { @board_entry_comment.should have(1).errors_on(:user_id) }
end

describe BoardEntryComment, "は適切な値が定義されている場合 保存できる" do
  before(:each) do
    @board_entry_comment = BoardEntryComment.new({ :board_entry_id => 1, :user_id => 1, :contents => "hoge" })
  end

  it { @board_entry_comment.should be_valid }
  it do
    @board_entry_comment.save!
    @board_entry_comment.comment_created_time.should
  end
end

describe BoardEntryComment, '#editable?' do
  before do
    @bob = create_user :user_options => {:name => 'ボブ', :admin => true}, :user_uid_options => {:uid => 'boob'}
    @bob_s_comment = BoardEntryComment.create({:board_entry_id => 1, :user_id => @bob.id, :contents => 'contents', :board_entry_id => create_board_entry.id})
    @alice = create_user :user_options => {:name => 'アリス', :admin => true}, :user_uid_options => {:uid => 'alice'}
  end
  describe 'コメントの所属する記事の閲覧権限がある場合' do
    before do
      @board_entry = create_board_entry
      BoardEntry.should_receive(:find).and_return(@board_entry)
    end
    describe 'コメントの所有者が指定されたユーザの場合' do
      it '編集権限があると判定される(trueが返る)こと' do
        @bob_s_comment.editable?(@bob).should be_true
      end
    end
    describe 'コメントの所有者が指定されたユーザではない場合' do
      it '編集権限がないと判定される(falseが返る)こと' do
        @bob_s_comment.editable?(@alice).should be_false
      end
    end
  end
  describe 'コメントの所属する記事の閲覧権限がない場合' do
    before do
      BoardEntry.should_receive(:find).and_return(nil)
    end
    describe 'コメントの所有者が指定されたユーザの場合' do
      it '編集権限がないと判定される(falseが返る)こと' do
        @bob_s_comment.editable?(@bob).should be_false
      end
    end
    describe 'コメントの所有者が指定されたユーザではない場合' do
      it '編集権限がないと判定される(falseが返る)こと' do
        @bob_s_comment.editable?(@alice).should be_false
      end
    end
  end
end

