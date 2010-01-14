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

describe CollaborationApp::Oauth::Backend, '#add_access_token' do
  before do
    @app_name = 'wiki'
    @backend = CollaborationApp::Oauth::Backend.new @app_name
  end
  describe 'identity_urlに一致するユーザが存在する場合' do
    before do
      @openid = 'http://example.com/id/boob'
      @bob = create_user :user_uid_options => {:uid => 'boob'}
    end
    describe '指定アプリに対する、対象ユーザのアクセストークンが登録済みの場合' do
      before do
        @oauth_token = @bob.user_oauth_accesses.create! :app_name => @app_name, :token => 'token', :secret => 'secret'
      end
      describe '登録済みのtokenと指定されたtokenが一致する場合' do
        it 'user_oauth_accessesが変化しないこと' do
          lambda do
            @backend.add_access_token @openid, 'token', 'secret'
            @oauth_token.reload
          end.should_not change(@oauth_token.attributes, :values)
        end
      end
      describe '登録済みのtokenと指定されたtokenが一致しない場合' do
        it 'user_oauth_accessesが指定されたtokenで更新されること' do
          lambda do
            @backend.add_access_token @openid, 'new_token', 'secret'
            @oauth_token.reload
          end.should change(@oauth_token, :token).to('new_token')
        end
      end
    end
    describe '指定アプリに対する、対象ユーザのアクセストークンが未登録の場合' do
      it 'user_oauth_accessesに登録されること' do
        lambda do
          @backend.add_access_token @openid, 'token', 'secret'
        end.should change(UserOauthAccess, :count).by(1)
      end
    end
  end
  describe 'identity_urlに一致するユーザが存在しない場合' do
    it 'user_oauth_accessesに登録されないこと' do
      lambda do
        @backend.add_access_token @openid, 'token', 'secret'
      end.should_not change(UserOauthAccess, :count)
    end
  end
end

