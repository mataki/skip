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

require File.dirname(__FILE__) + '/../../../spec_helper'

describe CollaborationApp::Oauth::Client, '#client' do
  before do
    @app_name = 'wiki'
    @provider_url = 'http://skip/wiki/'
    apps_hash = {@app_name => {'name' => 'SKIP-WIKI', 'root_url' => @provider_url}}
    SkipEmbedded::InitialSettings['collaboration_apps'] = apps_hash
  end
  describe '指定されたサービスがproviderとして登録されていない場合' do
    before do
      OauthProvider.should_receive(:find_by_app_name).and_return(nil)
      @synchronizer = TestSynchronizer.new(@app_name)
      @skip_url = 'http://skip'
      SkipEmbedded::InitialSettings['protocol'] = 'http://'
      SkipEmbedded::InitialSettings['host_and_port'] = 'skip'
      @client = stub(SkipEmbedded::RpService::Client, :key => 'token', :secret => 'secret')
      @client.stub!(:backend=)
      SkipEmbedded::RpService::Client.stub!(:register!).and_return(@client)
    end
    it 'SKIPを指定したサービスにconsumerとして登録しにいくこと' do
      SkipEmbedded::RpService::Client.should_receive(:register!).with(@app_name, @provider_url, :url => @skip_url)
      @synchronizer.client
    end
    it '指定したサービスのconsumer_tokenとconsumer_keyが保存されること' do
      lambda do
        @synchronizer.client
      end.should change(OauthProvider, :count).by(1)
    end
    it 'Clientオブジェクトが返ること' do
      client = @synchronizer.client
      client.key.should == 'token'
      client.secret.should == 'secret'
    end
  end
  describe '指定されたサービスがproviderとして登録されている場合' do
    before do
      @oauth_provider = OauthProvider.new(:app_name => 'wiki', :token => 'token', :secret => 'secret')
      OauthProvider.should_receive(:find_by_app_name).and_return(@oauth_provider)
      @synchronizer = TestSynchronizer.new(@app_name)
    end
    it 'Clientオブジェクトが返ること' do
      client = @synchronizer.client
      client.key.should == 'token'
      client.secret.should == 'secret'
    end
  end

  class TestSynchronizer
    include CollaborationApp::Oauth::Client
    def initialize name
      @name = name
    end
  end
end
