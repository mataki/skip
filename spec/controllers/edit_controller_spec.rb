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

describe EditController do
  fixtures :users, :groups, :board_entries, :user_uids
  before(:each) do
    @user = users(:a_user)
    @a_protected_group = groups(:a_protected_group1)
    session[:auth_session_token] = @user.auth_session_token
  end

  describe "GET 'index'" do
    it "should be successful" do
      get 'index'
      response.should be_success
    end
  end

  describe "GET 'index with GROUP_BBS" do
    it "should be successful" do
      get :index, { :entry_type => BoardEntry::GROUP_BBS, :symbol => 'gid:' + @a_protected_group.gid }
      response.should be_success
    end
  end

  describe "POST 'create with right params" do
    it "should be successful" do
      post :create,
      { :entry_type=>"DIARY", :trackbacks=>"", :publication_type=>"public", :sent_mail=>{"send_flag"=>"1"},
        :contents_hiki=>SkipFaker.rand_char, :editor_mode=>"hiki",
        :board_entry=>{
          :entry_type=>"DIARY",
          :category=>"",
          "date(1i)"=>"2008",
          :title=>SkipFaker.rand_char,
          :symbol=>"uid:" + @a_user.uid,
          "date(2i)"=>"3",
          "date(3i)"=>"28",
          "date(4i)"=>"19",
          "date(5i)"=>"55",
          :ignore_times=>"0"}}
      @board_entry = assigns(:board_entry)
      response.should redirect_to(@board_entry.get_url_hash)
    end
  end

  describe "GET 'edit with right params" do

    it "should be successful" do
      get :edit, { :symbol=>"uid:" + @a_user.uid, :id=> @a_entry.id }
      response.should be_success
    end
  end
end
# 途中
describe EditController, "GET #index" do
  before do
    user_login
    session[:user_symbol] = "uid:skip"

    @title_prefix = 'とあるユーザ/グループのブログ/掲示板'
    controller.stub!(:write_place_name).and_return(@title_prefix)
  end
  describe "ブログを書くの場合" do
    before do
      get :index
    end
    it { response.should render_template('edit/index') }
    it "適切なインスタンス変数が設定されていること" do
      assigns[:title].should == "#{@title_prefix}を書く"
      assigns[:main_menu].should == "マイブログ"
    end
  end
  describe "掲示板を書くの場合" do
    before do
      get :index, :symbol => "gid:hoge"
    end
    it { response.should render_template('edit/index') }
    it "適切なインスタンス変数が設定されていること" do
      assigns[:title].should == "#{@title_prefix}を書く"
      assigns[:main_menu].should == "グループ"
    end
  end
end
# 途中
describe EditController, "GET #edit" do
  before do
    user_login
    session[:user_symbol] = "uid:skip"

    @board_entry = stub_model(BoardEntry)
    BoardEntry.stub!(:find).and_return(@board_entry)
    BoardEntry.stub!(:get_categories_hash)
    @title_prefix = 'とあるユーザ/グループのブログ/掲示板'
    controller.stub!(:write_place_name).and_return(@title_prefix)
  end
  describe "ブログの場合" do
    before do
      get :edit, :id => 1, :symbol => 'uid:skip'
    end
    it { response.should be_redirect }
    it "適切なインスタンス変数が設定されていること" do
      assigns[:title].should == "#{@title_prefix}を編集する"
      assigns[:main_menu].should == "マイブログ"
    end
  end
  describe "掲示板の場合" do
    before do
      get :edit, :id => 1, :symbol => 'gid:skip'
    end
    it { response.should be_redirect }
    it "適切なインスタンス変数が設定されていること" do
      assigns[:title].should == "#{@title_prefix}を編集する"
      assigns[:main_menu].should == "グループ"
    end
  end
end

describe EditController, "#destroy" do
  before do
    user_login

    controller.stub!(:setup_layout)
    controller.stub!(:authorize_to_edit_board_entry?).and_return(true)

    @board_entry = stub_model(BoardEntry, :id => 2, :user_id => 2, :entry_type => "DIARY", :symbol => 'uid:skip')
    @board_entry.should_receive(:destroy).and_return(@board_entry)
    BoardEntry.should_receive(:find).and_return(@board_entry)

    @url = @board_entry.get_url_hash.delete_if{|key,val| key == :entry_id}

    post :destroy, :id => "1"
  end
  it { response.should redirect_to(@url) }
  it "flashメッセージが設定されていること" do
    flash[:notice].should == '削除しました。'
  end
end

describe EditController, "#create" do
  before do
    user_login
    @user_symbol = "uid:hoge"
    session[:user_symbol] = @user_symbol
  end
  describe "正しく作成される場合" do
    before do
      new_trackbacks = mock('new_trackbacks')

      @file1 = mock_uploaed_file
      @file2 = mock_uploaed_file

      @entry = stub_model(BoardEntry, :entry_type => "DIARY")
      @entry.should_receive(:save).and_return(true)
      @entry.should_receive(:send_trackbacks).and_return(["", new_trackbacks])
      @entry.should_receive(:cancel_mail)

      controller.should_receive(:setup_layout).and_return(true)
      controller.should_receive(:validate_params).and_return(true)
      controller.should_receive(:analyze_params).and_return([["sid:allusers"], []])
      controller.should_receive(:make_trackback_message).with(new_trackbacks)

      BoardEntry.stub!(:new).and_return(@entry)
    end
    describe "メールを送る場合" do
      before do
        @entry.should_receive(:send_mail?).and_return(true)
        @entry.should_receive(:prepare_send_mail)
        post :create, {
          :board_entry => { :symbol => @user_symbol, :send_mail => "1" }, :image => { "1" => @file1, "2" => @file2 }
        }
      end
      it "作成された掲示板にリダイレクトされる" do
        response.should redirect_to(@entry.get_url_hash)
      end
      it "メールが送信が予約されること" do
      end
      it "flashメッセージが設定されていること" do
        flash[:notice].should == '正しく作成されました。'
      end
    end

    describe "メールを送らない場合" do
      before do
        @entry.should_not_receive(:prepare_send_mail)
        @entry.should_receive(:send_mail?).and_return(false)
        post :create, {
          :board_entry => { :symbol => @user_symbol, :send_mail => "0" }, :image => { "1" => @file1, "2" => @file2 }
        }
      end
      it "作成された掲示板にリダイレクトされる" do
        response.should redirect_to(@entry.get_url_hash)
      end
      it "flashメッセージが設定されていること" do
        flash[:notice].should == '正しく作成されました。'
      end
      it "メール送信が予約されないこと" do
      end
    end
  end
end

describe EditController, "#analize_params" do
  before do
    @params = {
      :publication_type => "public",
      :editor_symbol => "true",
      :entry_type => "DIARY",
      :publication_symbols_value => "uid:100001,uid:a_group_owned_user,gin:a_protected_group1",
      :editor_symbols_value => "uid:100001,uid:a_group_owned_user,gin:hoge",
      :board_entry => { :symbol => "gid:a_protected_group1" }
    }
    @board_entry = stub_model(BoardEntry, :user_id => 1)
    User.stub!(:find).and_return(stub_model(User, :symbol => "uid:a_user"))
  end
  describe "publication_type が public の場合" do
    describe "ブログの場合" do
      before do
        controller.stub!(:params).and_return(@params)
        @result = controller.send(:analyze_params, @board_entry)
      end
      it "firstに sid:allusers が返ること" do
        @result.first.should == [Symbol::SYSTEM_ALL_USER]
      end
      it "lastに 空配列 が返ること" do
        @result.last.should == []
      end
    end
    describe "掲示板の場合" do
      before do
        controller.stub!(:params).and_return(@params.merge(:entry_type => BoardEntry::GROUP_BBS))
        @result = controller.send(:analyze_params, @board_entry)
      end
      it "firstに sid:allusers が返ること" do
        @result.first.should == [Symbol::SYSTEM_ALL_USER]
      end
      it "lastに true が返ること" do
        @result.last.should == ["true"]
      end
    end
  end
  describe "publication_type が private の場合" do
    before do
      @params.update(:publication_type => "private")
    end
    describe "ブログの場合" do
      before do
        controller.stub!(:params).and_return(@params)
        @result = controller.send(:analyze_params, @board_entry)
      end
      it "firstに 作者のuid が返ること" do
        @result.first.should == ["uid:a_user"]
      end
      it "lastに 空配列 が返ること" do
        @result.last.should == []
      end
    end
    describe "掲示板の場合" do
      before do
        controller.stub!(:params).and_return(@params.merge(:entry_type => BoardEntry::GROUP_BBS))
        @result = controller.send(:analyze_params, @board_entry)
      end
      it "firstに グループのidと作者のid が返ること" do
        @result.first.should == ["gid:a_protected_group1", "uid:a_user"]
      end
      it "lastに true が返ること" do
        @result.last.should == ["true"]
      end
    end
  end
  describe "publication_type が protected の場合" do
    before do
      @params.update(:publication_type => "protected")
    end
    describe "ブログの場合" do
      before do
        controller.stub!(:params).and_return(@params)
        @result = controller.send(:analyze_params, @board_entry)
      end
      it "firstに 作者のuid が返ること" do
        @result.first.should == ["uid:100001", "uid:a_group_owned_user", "gin:a_protected_group1", "uid:a_user"]
      end
      it "lastに 空配列 が返ること" do
        @result.last.should == ["uid:100001", "uid:a_group_owned_user", "gin:hoge"]
      end
    end
    describe "掲示板の場合" do
      before do
        controller.stub!(:params).and_return(@params.merge(:entry_type => BoardEntry::GROUP_BBS))
        @result = controller.send(:analyze_params, @board_entry)
      end
      it "firstに グループのidと作者のid が返ること" do
        @result.first.should == ["uid:100001", "uid:a_group_owned_user", "gin:a_protected_group1", "uid:a_user"]
      end
      it "lastに true が返ること" do
        @result.last.should == ["uid:100001", "uid:a_group_owned_user", "gin:hoge"]
      end
    end
  end
end
