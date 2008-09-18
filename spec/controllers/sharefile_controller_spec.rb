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
