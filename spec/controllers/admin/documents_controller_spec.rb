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
          stub_flash_now
          get :index, :target => 'rules'
        end
        it { flash[:error].should_not be_nil }
        it { response.code.should == '403' }
      end
      describe 'その他エラーが発生する場合' do
        before do
          controller.should_receive(:open).and_raise(Errno::EBUSY)
          stub_flash_now
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
      stub_flash_now
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
      target = 'rules'
      file = mock('file')
      document = contents
      document = Admin::DocumentsController::HTML_WRAPPER.sub('BODY', document)
      document = document.sub('TITLE_STR', ERB::Util.h(target).humanize)
      file.should_receive(:write).with(document)
      controller.should_receive(:open).with(anything(), 'w').and_yield(file)
      post :update, :target => target, :documents => {:rules => contents}
    end
    it { flash[:notice].should_not be_nil }
    it { response.should be_redirect }
  end
  describe '対象ファイルの読み込みに失敗する場合' do
    describe '対象ファイルに対する権限が無い場合' do
      before do
        controller.should_receive(:open).and_raise(Errno::EACCES)
        stub_flash_now
        post :update, :target => 'rules', :documents => {:rules => ''}
      end
      it { flash[:error].should_not be_nil }
      it { response.code.should == '403' }
      it { response.should render_template('index') }
    end
    describe 'その他エラーが発生する場合' do
      before do
        controller.should_receive(:open).and_raise(Errno::EBUSY)
        stub_flash_now
        post :update, :target => 'rules', :documents => {:rules => ''}
      end
      it { flash[:error].should_not be_nil }
      it { response.code.should == '500' }
      it { response.should render_template('index') }
    end
  end
end

describe Admin::DocumentsController, 'GET /revert' do
  before do
    admin_login
    controller.stub!(:check_params)
    get :revert
  end
  it { response.should redirect_to(admin_documents_path) }
end

describe Admin::DocumentsController, 'POST /revert' do
  before do
    admin_login
    controller.should_receive(:check_params).at_least(:once)
  end
  describe '処理に成功する場合' do
    before do
      default_file = mock('default_file')
      target_file = mock('target_file')
      controller.should_receive(:open).with(anything(), 'r').and_yield(default_file)
      controller.should_receive(:open).with(anything(), 'w').and_yield(target_file)
      target_file.should_receive(:write)
      default_file.should_receive(:read)
      @target = 'rules'
      post :revert, :target => @target
    end
    it { response.should redirect_to(admin_documents_path(:target => @target)) }
    it { assigns[:topics].should_not be_nil }
  end
  describe '処理に失敗する場合' do
    describe '対象ファイルに対する権限がない場合' do
      before do
        controller.should_receive(:open).and_raise(Errno::EACCES)
        stub_flash_now
        post :revert, :target => 'title_logo'
      end
      it { flash[:error].should_not be_nil }
      it { response.code.should == '403' }
      it { response.should render_template('index') }
    end
    describe 'その他エラーが発生する場合' do
      before do
        controller.should_receive(:open).and_raise(Errno::EBUSY)
        stub_flash_now
        post :revert, :target => 'title_logo'
      end
      it { flash[:error].should_not be_nil }
      it { response.code.should == '500' }
      it { response.should render_template('index') }
    end
  end
end
