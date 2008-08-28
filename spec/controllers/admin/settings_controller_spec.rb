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

describe Admin::SettingsController, 'GET /index' do
  before do
    admin_login
    get :index
  end
  it { response.should be_success }
end

describe Admin::SettingsController, 'POST /update_all' do
  before do
    admin_login
  end
  describe '通常のsettingsパラメタがひとつ送信された場合' do
    before do
      @key, @value = 'hoge', 'hoge_val'
    end
    it '保存処理が一回呼ばれる事' do
      Admin::Setting.should_receive('[]=').once.with(@key.to_sym, @value)
      post :update_all, 'settings' => {@key => @value}
    end
  end
  describe '通常のsettingsパラメタがふたつ送信された場合' do
    before do
      @key1, @value1 = 'hoge', 'hoge_val'
      @key2, @value2 = 'fuga', 'fuga_val'
    end
    it '保存処理が二回呼ばれる事' do
      Admin::Setting.should_receive('[]=').once.with(@key1.to_sym, @value1)
      Admin::Setting.should_receive('[]=').once.with(@key2.to_sym, @value2)
      post :update_all, 'settings' => {@key1 => @value1, @key2 => @value2}
    end
  end
  describe '中身が配列のsettingsパラメタが送信された場合' do
    before do
      @key, @value = 'hoge', ['hoge', '']
      @expected_value = ['hoge']
    end
    it '空の値が取り除かれること' do
      Admin::Setting.should_receive('[]=').once.with(@key.to_sym, @expected_value)
      post :update_all, 'settings' => {@key => @value}
    end
  end
  describe '中身がHashのsettingsパラメタが送信された場合' do
    before do
      @key, @value = 'hoge', {'aaa' => 'aaa', 'bbb' => 'bbb'}
    end
    it 'Hashが保存されること' do
      Admin::Setting.should_receive('[]=').once.with(@key.to_sym, @value)
      post :update_all, :settings => {@key => @value}
    end
  end
  describe 'メール設定の保存を行う場合' do
    it 'メール設定の再設定処理が行われること' do
      ActionMailer::Base.should_receive(:smtp_settings=)
      post :update_all, :tab => 'mail'
    end
  end
  describe 'メール設定以外の保存を行う場合' do
    it 'メール設定の再設定処理が行われないこと' do
      ActionMailer::Base.should_not_receive(:smtp_settings=)
      post :update_all, :tab => 'literal'
    end
  end
end
