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

describe AntennaController, 'GET ado_add_antenna_item' do
  before do
    user_login
    @antenna_item = stub_model(AntennaItem)
    AntennaItem.stub!(:new).and_return(@antenna_item)
    controller.stub!(:login_user_antenna?).and_return(true)
    @item = stub_model(User)
    Symbol.stub!(:get_item_by_symbol).and_return(@item)
  end
  describe 'ログインセッションのユーザ自身のアンテナではない場合' do
    before do
      controller.stub!(:login_user_antenna?).and_return(false)
      post :ado_add_antenna_item
    end
    it 'ステータスコードとして400が返ること' do
      response.code.should == '400'
    end
    it 'アンテナアイテムが追加できない旨メッセージ表示' do
      response.body.should == '不正なアンテナが指定されました。'
    end
  end
  describe '不正なオーナーが指定された場合' do
    before do
      Symbol.stub!(:get_item_by_symbol).and_return(nil)
      post :ado_add_antenna_item
    end
    it 'ステータスコードとして400が返ること' do
      response.code.should == '400'
    end
    it 'アンテナアイテムが追加できない旨メッセージ表示' do
      response.body.should == '存在しないオーナーが指定されました。'
    end
  end
  describe 'アンテナアイテムの追加に成功する場合' do
    before do
      AntennaItem.should_receive(:new).with(:antenna_id => params[:antenna_id], :value_type => :symbol.to_s, :value => params[:symbol])
      @antenna_item.should_receive(:save).and_return(true)
      post :ado_add_antenna_item
    end
    it '追加したアンテナの部分テンプレートがrenderされること' do
      response.should render_template('antenna/antenna_item')
    end
  end
  describe 'アンテナアイテムの追加に失敗する場合' do
    before do
      @antenna_item.should_receive(:save).and_return(false)
      post :ado_add_antenna_item
    end
    it 'ステータスコードとして400が返ること' do
      response.code.should == '400'
    end
  end
end
