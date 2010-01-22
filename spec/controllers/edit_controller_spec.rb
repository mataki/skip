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
    describe "フォーラムの場合" do
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
    describe "フォーラムの場合" do
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
    describe "フォーラムの場合" do
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
