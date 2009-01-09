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

describe BoardEntriesController, 'POST #ado_create_nest_comment' do
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

describe BoardEntriesController, 'POST #ado_pointup' do
  before do
    @user = user_login
  end
  describe '指定した記事が見つかる場合' do
    before do
      @board_entry = stub_model(BoardEntry)
      BoardEntry.should_receive(:find).and_return(@board_entry)
    end
    describe '指定した記事の閲覧権限がある場合' do
      before do
        controller.should_receive(:readable?).with(@board_entry).and_return(true)
      end
      describe '指定した記事の作成者ではない場合' do
        before do
          @board_entry.should_receive(:writer?).with(@user.id).and_return(false)
          @state = stub_model(BoardEntryPoint)
          @state.stub!(:increment!)
          @board_entry.stub!(:state).and_return(@state)
        end
        it 'ポイントがインクリメントされること' do
          @state.should_receive(:increment!)
          @board_entry.stub!(:state).and_return(@state)
          post :ado_pointup
        end
        it 'GoodJobボタンに表示するメッセージが設定されること' do
          post :ado_pointup
          response.body.should == '0 GoodJob'
        end
        it '200のレスポンスコードが返ること' do
          post :ado_pointup
          response.code.should == '200'
        end
      end
      describe '指定した記事の作成者である場合' do
        before do
          @board_entry.should_receive(:writer?).with(@user.id).and_return(true)
          post :ado_pointup
        end
        it '権限がない旨のメッセージが設定されること' do
          response.body.should == 'この操作は、許可されていません。'
        end
        it '403のレスポンスコードが返ること' do
          response.code.should == '403'
        end
      end
    end
    describe '指定した記事の閲覧権限がない場合' do
      before do
        controller.should_receive(:readable?).with(@board_entry).and_return(false)
        post :ado_pointup
      end
      it '権限がない旨のメッセージが設定されること' do
        response.body.should == 'この操作は、許可されていません。'
      end
      it '403のレスポンスコードが返ること' do
        response.code.should == '403'
      end
    end
  end
  describe '指定した記事が見つからない場合' do
    before do
      BoardEntry.should_receive(:find).and_raise(ActiveRecord::RecordNotFound)
      post :ado_pointup
    end
    it '記事が見つからない旨のメッセージが設定されること' do
      response.body.should == '対象の記事が存在しません。'
    end
    it '404のレスポンスコードが返ること' do
      response.code.should == '404'
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

describe BoardEntriesController, '#readable?' do
  before do
    @user = user_login
    @user.stub!(:symbol)
    @board_entry = stub_model(BoardEntry)
  end
  describe 'ログインユーザの記事の場合' do
    before do
      @user.should_receive(:symbol).and_return('uid:owner')
      @board_entry.should_receive(:symbol).and_return('uid:owner')
    end
    it 'trueが返ること' do
      controller.send(:readable?, @board_entry).should be_true
    end
  end
  describe 'ログインユーザの記事ではない場合' do
    describe 'ログインユーザ所属グループの記事の場合' do
      before do
        controller.should_receive(:login_user_groups).and_return(['gid:skip_dev'])
        @board_entry.should_receive(:symbol).at_least(:once).and_return('gid:skip_dev')
      end
      it 'trueが返ること' do
        controller.send(:readable?, @board_entry).should be_true
      end
    end
    describe 'ログインユーザ所属グループの記事ではない場合' do
      before do
        controller.should_receive(:login_user_groups).at_least(:once).and_return(['gid:skip_dev'])
        @board_entry.should_receive(:symbol).at_least(:once).and_return('uid:owner')
      end
      describe 'ログインユーザに公開されている記事の場合' do
        before do
          @board_entry.should_receive(:publicate?).and_return(true)
        end
        it 'trueが返ること' do
          controller.send(:readable?, @board_entry).should be_true
        end
      end
      describe 'ログインユーザに公開されていない記事の場合' do
        before do
          @board_entry.should_receive(:publicate?).and_return(false)
        end
        it 'falseが返ること' do
          controller.send(:readable?, @board_entry).should be_false
        end
      end
    end
  end
end
