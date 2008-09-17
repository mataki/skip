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

describe EditController do
  fixtures :users, :groups, :board_entries, :user_uids
  before(:each) do
    @user = users(:a_user)
    @a_protected_group = groups(:a_protected_group1)
    session[:user_code] = @user.code
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
