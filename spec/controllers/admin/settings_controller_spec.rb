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

describe Admin::SettingsController, 'GET /index' do
  before do
    admin_login
  end
  describe 'tabパラメタの指定がない場合' do
    before do
      get :index
    end
    it { response.should be_redirect }
  end

  describe 'tabパラメタの指定がある場合' do
    before do
      get :index, :tab => 'mail'
    end
    it { response.should be_success }
  end
end

describe Admin::SettingsController, 'POST /update_all' do
  before do
    admin_login
  end
  describe 'バリデーションエラーがない場合' do
    before do
      Admin::Setting.should_receive(:error_messages).and_return([])
    end
    describe '通常のsettingsパラメタがひとつ送信された場合' do
      before do
        @key, @value, @setting = 'hoge', 'hoge_val', mock_model(Admin::Setting)
        Admin::Setting.stub!('[]=').once.with(@key.to_sym, @value).and_return(@setting)
      end
      it '保存処理が一回呼ばれる事' do
        Admin::Setting.should_receive('[]=').once.with(@key.to_sym, @value).and_return(@setting)
        post :update_all, 'settings' => {@key => @value}
      end
      it "保存に成功したメッセージがflashに格納されていること" do
        post :update_all, 'settings' => {@key => @value}
        flash[:notice].should == 'Settings were saved successfully.'
      end
    end
    describe '通常のsettingsパラメタがふたつ送信された場合' do
      before do
        @key1, @value1, @setting1 = 'hoge', 'hoge_val', mock_model(Admin::Setting, :errors => [])
        @key2, @value2, @setting2 = 'fuga', 'fuga_val', mock_model(Admin::Setting, :errors => [])
      end
      it '保存処理が二回呼ばれる事' do
        Admin::Setting.should_receive('[]=').once.with(@key1.to_sym, @value1).and_return(@setting1)
        Admin::Setting.should_receive('[]=').once.with(@key2.to_sym, @value2).and_return(@setting2)
        post :update_all, 'settings' => {@key1 => @value1, @key2 => @value2}
      end
    end
    describe '中身が配列のsettingsパラメタが送信された場合' do
      before do
        @key, @value, @setting = 'hoge', ['hoge', ''], mock_model(Admin::Setting, :errors => [])
        @expected_value = ['hoge']
      end
      it '空の値が取り除かれること' do
        Admin::Setting.should_receive('[]=').once.with(@key.to_sym, @expected_value).and_return(@setting)
        post :update_all, 'settings' => {@key => @value}
      end
    end
    describe '中身がHashのsettingsパラメタが送信された場合' do
      before do
        @key, @value, @setting = 'hoge', {'aaa' => 'aaa', 'bbb' => 'bbb'}, mock_model(Admin::Setting, :errors => [])
      end
      it 'Hashが保存されること' do
        Admin::Setting.should_receive('[]=').once.with(@key.to_sym, @value).and_return(@setting)
        post :update_all, :settings => {@key => @value}
      end
    end
  end
  describe 'バリデーションエラーがあった場合' do
    before do
      Admin::Setting.should_receive(:error_messages).and_return(['error'])
    end
    describe '通常のsettingsパラメタがひとつ送信された場合' do
      before do
        @key, @value, @setting = 'hoge', 'hoge_val', mock_model(Admin::Setting)
        Admin::Setting.stub!('[]=').once.with(@key.to_sym, @value).and_return(@setting)
      end
      it 'エラーメッセージが設定されること' do
        post :update_all, 'settings' => {@key => @value}
        assigns['error_messages'].should_not be_empty
      end
    end
  end
end
