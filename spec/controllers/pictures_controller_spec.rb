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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PicturesController, '#destroy' do
  before do
    @current_user = user_login
    @current_user.stub!(:id).and_return(77)
  end
  describe 'プロフィール画像が設定されている場合' do
    before do
      @picture = stub_model(Picture)
      @current_user.stub_chain(:pictures, :find).and_return(@picture)
    end
    describe 'プロフィール画像の変更が許可されている場合' do
      before do
        Admin::Setting.should_receive(:enable_change_picture).and_return(true)
        @picture.stub!(:destroy)
      end
      it 'プロフィール画像の削除が行われること' do
        @picture.should_receive(:destroy)
        delete :destroy
      end
      it '「画像を削除しました」というメッセージが設定されること' do
        delete :destroy
        flash[:notice].should == 'Picture was deleted successfully.'
      end
      it 'プロフィール画像管理画面にリダイレクトされること' do
        delete :destroy
        response.should be_redirect
      end
    end
    describe 'プロフィール画像の変更が許可されていない場合' do
      before do
        Admin::Setting.should_receive(:enable_change_picture).and_return(false)
      end
      it '「画像の変更は許可されていません。」というメッセージが設定されること' do
        delete :destroy
        flash[:warn].should == 'Picture could not be changed.'
      end
      it 'プロフィール画像管理画面にリダイレクトされること' do
        delete :destroy
        response.should be_redirect
      end
    end
  end
  describe 'プロフィール画像が設定されていない場合' do
    before do
      @current_user.stub_chain(:pictures, :find).and_return(nil)
    end
    it '「プロフィール画像が存在しないため、削除できませんでした。」というメッセージが設定されること' do
      delete :destroy
      flash[:warn].should == 'Picture could not be deleted since it does not found.'
    end
    it 'プロフィール画像管理画面にリダイレクトされること' do
      delete :destroy
      response.should be_redirect
    end
  end
end
