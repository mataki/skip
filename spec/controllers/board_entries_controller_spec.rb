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

describe BoardEntriesController, 'GET /ado_create_nest_comment' do
  before do
    user_login
    @comment = stub_model(BoardEntryComment)
    @entry = stub_model(BoardEntry)
    @comment.stub!(:board_entry).and_return(@entry)
    BoardEntryComment.stub!(:find).and_return(@comment)
    BoardEntry.stub!(:make_conditions).and_return({})
    BoardEntry.stub!(:find).and_return(@entry)
  end

  describe '親コメントが存在しない場合' do
    before do
      BoardEntryComment.should_receive(:find).and_raise(ActiveRecord::RecordNotFound)
      post :ado_create_nest_comment
    end
    it 'ステータスコード404が設定されること' do
      response.code.should == '404'
    end
    it '親コメントが存在しない旨のメッセージが設定されること' do
      response.body.should == '親コメントが存在しません。再読み込みして下さい。'
    end
  end

  describe 'コメントの中身が空の場合' do
    before do
      post :ado_create_nest_comment, :contents => ''
    end
    it 'ステータスコード400が設定されること' do
      response.code.should == '400'
    end
    it 'コメントは必須である旨のメッセージが設定されること' do
      response.body.should == 'コメントの入力は必須です。'
    end
  end

  describe 'コメントを行おうとしているエントリが存在しない場合' do
    before do
      BoardEntry.should_receive(:find).and_return(nil)
      post :ado_create_nest_comment, :contents => 'contents'
    end
    it 'ステータスコード404が設定されること' do
      response.code.should == '404'
    end
    it '対象の記事が存在しない旨のメッセージが設定されること' do
      response.body.should == 'コメント対象の記事は存在しません。'
    end
  end
end

describe BoardEntriesController, "GET #destroy_comment" do
  before do
    user_login

    session[:user_symbol] = "gid:skip"

    @board_entry = stub_model(BoardEntry, :id => 10, :symbol => "gid:skip")
    @board_entry_comment = stub_model(BoardEntryComment)
    @board_entry_comment.stub!(:board_entry).and_return(@board_entry)

    BoardEntryComment.stub!(:find).and_return(@board_entry_comment)
  end
  describe "削除に成功する場合" do
    before do
      @board_entry_comment.stub!(:children).and_return([])
      @board_entry_comment.should_receive(:destroy)

      post :destroy_comment
    end
    it { response.should redirect_to(:action => "forward", :id => @board_entry.id ) }
    it "flashにメッセージが登録されていること" do
      flash[:notice].should == "コメントを削除しました。"
    end
  end
  describe "ネストのコメントが存在する場合" do
    before do
      @board_entry_comment.stub!(:children).and_return(["aa","aa"])
      @board_entry_comment.should_not_receive(:destroy)

      post :destroy_comment
    end
    it { response.should redirect_to(:action => "forward", :id => @board_entry.id ) }
    it "flashにメッセージが登録されていること" do
      flash[:warning].should == "このコメントに対するコメントがあるため削除できません。"
    end
  end
end
