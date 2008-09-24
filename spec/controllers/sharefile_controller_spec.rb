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

describe ShareFileController, "GET /download" do
  before do
    @user = user_login
    ShareFile.stub!(:make_conditions).and_return({})
    ShareFile.stub!(:find)
    File.stub!(:exist?)
  end
  describe '対象のShareFileが存在する場合' do
    before do
      @share_file = stub_model(ShareFile)
      @full_path = 'example.png'
      @share_file.stub!(:full_path).and_return(@full_path)
      ShareFile.should_receive(:find).and_return(@share_file)
    end
    describe '対象となる実体ファイルが存在する場合' do
      before do
        @share_file.stub!(:create_history)
        @controller.stub!(:nkf_file_name)
        @controller.stub!(:send_file)
        File.should_receive(:exist?).with(@full_path).and_return(true)
      end
      it '履歴が作成されること' do
        @share_file.should_receive(:create_history).with(@user.id)
        get :download
      end
      it 'ファイルがダウンロードされること' do
        @controller.should_receive(:send_file).with(@share_file.full_path, anything())
        get :download
      end
    end
    describe '対象となる実体ファイルが存在しない場合' do
      before do
        File.should_receive(:exist?).with(@full_path).and_return(false)
        get :download
      end
      it { flash[:warning].should_not be_nil }
      it { response.should be_redirect }
    end
  end
  describe '対象のShareFileが存在しない場合' do
    before do
      ShareFile.should_receive(:find).and_return(nil)
      get :download
    end
    it { flash[:warning].should_not be_nil }
    it { response.should be_redirect }
  end
end

describe ShareFileController, "POST #create" do
  before do
    user_login
    session[:user_id] = 1

    controller.stub!(:login_user_symbols).and_return(["uid:hoge"])
    controller.stub!(:valid_upload_files?).and_return(true)
  end
  describe "ファイルが一つの時" do
    before do
      @file1 = mock('file1', { :original_filename => "file1.png", :content_type => "text",
                      :size => 1000, :read => "" })

      post :create, { :symbol => "", :publication_type => "public", :owner_name => 'ほげ ほげ',
        :publication_symbols_value => "",
        :share_file => { "date(1i)" => "2008", "date(2i)" => "9", "date(3i)" => "19",
          "date(4i)" => "16", "date(5i)" => "07", :description => "description",
          :category => "hoge,hoge", :owner_symbol => "uid:hoge"},
        :file => { "1" => @file1 } }
    end
    it { response.body.should == "<script type='text/javascript'>window.opener.location.reload();window.close();</script>" }
    it { assigns[:error_messages].should be_empty }
  end
  describe "複数ファイルが送信された場合" do
    before do
      @file1 = mock('file1', { :original_filename => "file1.png", :content_type => "text",
                      :size => 1000, :read => "" })
      @file2 = mock('file2', { :original_filename => "file2.png", :content_type => "text",
                      :size => 1000, :read => "" })

      post :create, { :symbol => "", :publication_type => "public", :owner_name => 'ほげ ほげ',
        :publication_symbols_value => "",
        :share_file => { "date(1i)" => "2008", "date(2i)" => "9", "date(3i)" => "19",
          "date(4i)" => "16", "date(5i)" => "07", :description => "description",
          :category => "hoge,hoge", :owner_symbol => "uid:hoge"},
        :file => { "1" => @file1, "2" => @file2 } }
    end
    it { response.body.should == "<script type='text/javascript'>window.opener.location.reload();window.close();</script>" }
    it { assigns[:error_messages].should be_empty }
  end
end

describe ShareFileController, "POST #destroy" do
  before do
    user_login
  end
  describe "ファイルが見つからなかったとき" do
    before do
      ShareFile.stub!(:find).with("1").and_raise(ActiveRecord::RecordNotFound)
    end
    it "ActiveRecord::RecordNotFoundが発生するとこ" do
      lambda do
        post :destroy, :id => 1
      end.should raise_error(ActiveRecord::RecordNotFound)
    end
  end
  describe "削除権限がなかった場合" do
    before do
      @share_file = stub_model(ShareFile)
      ShareFile.stub!(:find).with("1").and_return(@share_file)

      controller.should_receive(:authorize_to_save_share_file?).and_return(false)

      post :destroy, :id => 1
    end
    it { response.should redirect_to(:controller => :mypage)}
  end
  describe "削除に成功した場合" do
    before do
      @share_file = stub_model(ShareFile, :owner_symbol_type => "group", :owner_symbol_id => "hoge")
      ShareFile.stub!(:find).with("1").and_return(@share_file)

      controller.should_receive(:authorize_to_save_share_file?).and_return(true)

      @share_file.should_receive(:destroy).and_return(@share_file)

      post :destroy, :id => 1
    end
    it { response.should redirect_to(:controller => "group", :action => "hoge", :id => "share_file") }
    it { flash[:notice].should == "ファイルの削除に成功しました。" }
  end
end

describe ShareFileController, 'POST /download_history_as_csv' do
  before do
    user_login
    ShareFile.stub!(:find)
    controller.stub!(:authorize_to_save_share_file?)
  end
  describe '対象のShareFileが存在する場合' do
    before do
      @csv_text, @file_name = 'test,test', 'test.csv'
      @share_file = stub_model(ShareFile)
      @share_file.stub!(:get_accesses_as_csv).and_return(@csv_text, @file_name)
      ShareFile.should_receive(:find).and_return(@share_file)
    end
    describe '権限のあるファイルの場合' do
      before do
        controller.should_receive(:authorize_to_save_share_file?).and_return(true)
      end
      it 'csvファイルがdownloadされること' do
        controller.stub!(:nkf_file_name)
        controller.should_receive(:send_data).with(@csv_text, anything())
        post :download_history_as_csv
      end
    end
    describe '権限のないファイルの場合' do
      before do
        controller.should_receive(:authorize_to_save_share_file?).and_return(false)
      end
      it '権限チェックエラーとなること' do
        controller.should_not_receive(:send_data)
        controller.should_receive(:redirect_to_with_deny_auth)
        post :download_history_as_csv
      end
    end
  end
end
