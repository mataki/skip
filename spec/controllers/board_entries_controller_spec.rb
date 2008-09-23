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

      get :destroy_comment
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

      get :destroy_comment
    end
    it { response.should redirect_to(:action => "forward", :id => @board_entry.id ) }
    it "flashにメッセージが登録されていること" do
      flash[:warning].should == "このコメントに対するコメントがあるため削除できません。"
    end
  end
end
