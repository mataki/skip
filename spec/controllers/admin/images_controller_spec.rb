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

describe Admin::ImagesController, 'GET /index' do
  before do
    admin_login
    get :index
  end
  it { assigns[:topics].should_not be_nil }
end

describe Admin::ImagesController, 'GET /update' do
  before do
    admin_login
    stub_image = stub(Admin::ImagesController::BaseImage)
    controller.stub!(:new_image).and_return(stub_image)
    controller.stub!(:check_params)
    get :update
  end
  it { response.should redirect_to(admin_images_path) }
end

describe Admin::ImagesController, 'POST /update' do
  before do
    admin_login
    controller.should_receive(:check_params).at_least(:once)
    controller.stub!(:valid_file?).and_return(true)
  end
  describe '不正なファイルの場合' do
    before do
      controller.should_receive(:valid_file?).with(anything(), :max_size => 300.kilobyte, :content_types => anything(), :extension => anything()).and_return(false)
      post :update, :target => 'header_logo', :header_logo => mock('upload_file')
    end
    it { response.should render_template('index') }
    it { assigns[:topics].should_not be_nil }
  end

  describe '正常なファイルの場合' do
    describe '対象ファイルの読み込みに成功する場合' do
      before do
        file = mock('file')
        file.should_receive(:write)
        upload_file = mock('upload_file')
        upload_file.should_receive(:read)
        controller.should_receive(:open).with(anything(), 'wb').and_yield(file)
        post :update, :target => 'header_logo', :header_logo => upload_file
      end
      it { flash[:notice].should_not be_nil }
      it { response.should be_redirect }
    end
    describe '対象ファイルに対する権限がない場合' do
      before do
        controller.should_receive(:open).and_raise(Errno::EACCES)
        stub_flash_now
        post :update, :target => 'header_logo', :header_logo => mock('upload_file')
      end
      it { flash[:error].should_not be_nil }
      it { response.code.should == '403' }
      it { response.should render_template('index') }
    end
    describe 'その他エラーが発生する場合' do
      before do
        controller.should_receive(:open).and_raise(Errno::EBUSY)
        stub_flash_now
        post :update, :target => 'header_logo', :header_logo => mock('upload_file')
      end
      it { flash[:error].should_not be_nil }
      it { response.code.should == '500' }
      it { response.should render_template('index') }
    end
  end
end

describe Admin::ImagesController, 'POST /revert' do
  before do
    admin_login
    controller.should_receive(:check_params).at_least(:once)
  end
  describe '処理に成功する場合' do
    before do
      default_file = mock('default_file')
      target_file = mock('target_file')
      controller.should_receive(:open).with(anything(), 'rb').and_yield(default_file)
      controller.should_receive(:open).with(anything(), 'wb').and_yield(target_file)
      target_file.should_receive(:write)
      default_file.should_receive(:read)
      post :revert, :target => 'header_logo'
    end
    it { response.should redirect_to(admin_images_path) }
    it { assigns[:topics].should_not be_nil }
  end
end
