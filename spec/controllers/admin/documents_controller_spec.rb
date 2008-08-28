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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::DocumentsController, 'GET /index' do
  before do
    admin_login
    controller.should_receive(:check_params).at_least(:once)
    controller.stub!(:open)
  end

  describe '対象ファイルが存在する場合' do
    describe '対象ファイルの読み込みに成功する場合' do
      before do
        controller.should_receive(:open)
        get :index, :target => 'rules'
      end
      it { response.should be_success }
    end
    describe '対象ファイルの読み込みに失敗する場合' do
      describe '対象ファイルに対する権限が無い場合' do
        before do
          controller.should_receive(:open).and_raise(Errno::EACCES)
          get :index, :target => 'rules'
        end
        it { flash[:error].should_not be_nil }
        it { response.code.should == '403' }
      end
      describe 'その他エラーが発生する場合' do
        before do
          controller.should_receive(:open).and_raise(Errno::EBUSY)
          get :index, :target => 'rules'
        end
        it { flash[:error].should_not be_nil }
        it { response.code.should == '500' }
      end
    end
  end
  describe '対象ファイルが存在しない場合' do
    before do
      controller.should_receive(:open).and_raise(Errno::ENOENT)
      get :index, :target => 'rules'
    end
    it { flash[:error].should_not be_nil }
    it { response.code.should == '404' }
  end
end

describe Admin::DocumentsController, 'POST /update' do
  before do
    admin_login
    controller.should_receive(:check_params).at_least(:once)
    controller.stub!(:open)
  end
  describe '対象ファイルの読み込みに成功する場合' do
    before do
      contents = 'skip rule'
      file = mock('file')
      file.should_receive(:write).with(contents)
      controller.should_receive(:open).with(anything(), 'w').and_yield(file)
      post :update, :target => 'rules', :documents => {:rules => contents}
    end
    it { flash[:notice].should_not be_nil }
    it { response.should be_redirect }
  end
  describe '対象ファイルの読み込みに失敗する場合' do
    describe '対象ファイルに対する権限が無い場合' do
      before do
        controller.should_receive(:open).and_raise(Errno::EACCES)
        post :update, :target => 'rules', :documents => {:rules => ''}
      end
      it { flash[:error].should_not be_nil }
      it { response.code.should == '403' }
      it { response.should render_template('index') }
    end
    describe 'その他エラーが発生する場合' do
      before do
        controller.should_receive(:open).and_raise(Errno::EBUSY)
        post :update, :target => 'rules', :documents => {:rules => ''}
      end
      it { flash[:error].should_not be_nil }
      it { response.code.should == '500' }
      it { response.should render_template('index') }
    end
  end
end
