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

require File.dirname(__FILE__) + '/../spec_helper'

describe CreateNewAdminUrl, '.execute' do
  before do
    @create_new_admin_url =  CreateNewAdminUrl.new
    CreateNewAdminUrl.stub!(:new).and_return(@create_new_admin_url)
  end
  describe 'activationsにレコードが存在する場合' do
    before do
      @activation = mock_model(Activation)
      Activation.should_receive(:first).and_return(@activation)
    end
    describe 'codeがnilの場合' do
      before do
        @activation.should_receive(:code).and_return(nil)
      end
      it '初期アカウントは登録済みである旨のメッセージ表示' do
        CreateNewAdminUrl.should_receive(:p).and_return('初期アカウントは登録済みです。')
        CreateNewAdminUrl.execute(:argv => [])
      end
    end
    describe 'codeがnot nilの場合' do
      before do
        @code = '123456789'
        @activation.stub!(:code).and_return(@code)
      end
      describe '起動オプションに--code指定がある場合' do
        it 'activation_codeの保存が行われること' do
          @activation.should_receive(:update_attributes)
          CreateNewAdminUrl.should_receive(:p)
          CreateNewAdminUrl.execute(:argv => ['--code'])
        end
      end
      describe '起動オプションに--code指定がない場合' do
        it 'activation_codeは発行済みである旨のメッセージ表示' do
          CreateNewAdminUrl.should_receive(:p).twice()
          CreateNewAdminUrl.execute(:argv => [])
        end
      end
    end
  end
  describe 'activationsにレコードが存在しない場合' do
    before do
      Activation.should_receive(:first).and_return(nil)
      @activation = mock_model(Activation)
    end
    describe '起動オプションに--code指定がある場合' do
      describe 'activationsの作成に成功する場合' do
        before do
          @code = '123456789'
          @activation.should_receive(:code).and_return(@code)
          @activation.should_receive(:save).and_return(true)
          Activation.should_receive(:new).and_return(@activation)
        end
      it '初期アカウント登録用ワンタイムURLを表示' do
        @url = 'http://hoge.jp'
        @create_new_admin_url.should_receive(:show_new_admin_url).with(@code).and_return(@url)
        CreateNewAdminUrl.should_receive(:p).twice()
        CreateNewAdminUrl.execute(:argv => ['--code'])
      end
    end
    describe 'activationsの作成に失敗する場合' do
      before do
        @activation.should_receive(:save).and_return(false)
        Activation.should_receive(:new).and_return(@activation)
      end
      it 'エラーが表示されること' do
        CreateNewAdminUrl.should_receive(:p).and_return('ワンタイムコードの保存に失敗しました。')
        CreateNewAdminUrl.execute(:argv => ['--code'])
      end
    end
    end
    describe '起動オプションに--code指定がない場合' do
      it 'codeの指定を促すメッセージ表示がされること' do
        CreateNewAdminUrl.should_receive(:p).and_return('activation_codeが未発行です。--helpを参照の上、codeを指定して下さい。')
        CreateNewAdminUrl.execute(:argv => [])
      end
    end
  end
end

describe CreateNewAdminUrl, '#show_new_admin_url' do
  include ActionController::UrlWriter
  default_url_options[:host] = 'localhost:3000'
  default_url_options[:protocol] = 'http'

  before do
    @create_new_admin_url = CreateNewAdminUrl.new
  end
  it '指定されたホストのアカウント作成処理へcodeパラメタ付きでアクセスするためのurlが返ってくること' do
    code = '123456789'
    @create_new_admin_url.show_new_admin_url(code).should == 'http://localhost:3000/admin/users/new/first?code=' + code
  end
  it 'URIエンコードされていること' do
    code = '12345&hoge=123%456'
    @create_new_admin_url.show_new_admin_url(code).should == 'http://localhost:3000/admin/users/new/first' + '?code=' + CGI.escape(code)
  end
end
