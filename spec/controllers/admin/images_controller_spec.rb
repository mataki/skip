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

describe Admin::ImagesController, 'GET /index' do
end

describe Admin::ImagesController, 'POST /update' do
  before do
    admin_login
    controller.should_receive(:check_params).at_least(:once)
    controller.stub!(:valid_file?).and_return(true)
  end
  describe '不正なファイルの場合' do
    before do
      controller.should_receive(:valid_file?).with(anything(), :max_size => 300.kilobyte, :content_types => anything()).and_return(false)
      post :update, :target => 'title_logo', :title_logo => mock('upload_file')
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
        post :update, :target => 'title_logo', :title_logo => upload_file
      end
      it { flash[:notice].should_not be_nil }
      it { response.should be_redirect }
    end
    describe '対象ファイルに対する権限がない場合' do
      before do
        controller.should_receive(:open).and_raise(Errno::EACCES)
        post :update, :target => 'title_logo', :title_logo => mock('upload_file')
      end
      it { flash[:error].should_not be_nil }
      it { response.code.should == '403' }
      it { response.should render_template('index') }
    end
    describe 'その他エラーが発生する場合' do
      before do
        controller.should_receive(:open).and_raise(Errno::EBUSY)
        post :update, :target => 'title_logo', :title_logo => mock('upload_file')
      end
      it { flash[:error].should_not be_nil }
      it { response.code.should == '500' }
      it { response.should render_template('index') }
    end
  end
end

