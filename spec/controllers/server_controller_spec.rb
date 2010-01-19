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

describe ServerController, "#index" do
  before do
    @login_user = user_login

    @id_url = "http://localhost/tekito"
  end
  describe "checkid_requestの場合" do
    before do
      id_url = "http://notmine.com"
      post :index, checkid_request_params.merge("openid.identity" => id_url, 'openid.claimed_id' => id_url)
    end
    it "ログイン画面にリダイレクトすること" do
      response.should redirect_to(login_url(:return_to => proceed_path))
    end
    it "sessionに情報が登録されていること" do
      session[:request_token].should_not be_nil
    end
  end
  describe "古いリクエストが存在して、OpenIDのリクエスト以外でindexにアクセスした場合" do
    before do
      fake_checkid_request(@login_user)
      @old_token = session[:request_token]
      post :index
    end
    it "古いsessionの情報は更新されていること" do
      session[:request_token].should_not == @old_token
    end
    it "open_id_requestsテーブルから削除されていること" do
      OpenIdRequest.find_by_token(@old_token)
    end
  end

  describe "associateリクエストが送られた場合" do
    before do
      post :index, associate_request_params
    end
    it "アクセスが成功すること" do
      response.should be_success
    end
    it "正しいパラメータがbodyに含まれていること" do
      response.body.should include('assoc_handle')
      response.body.should include('assoc_type')
      response.body.should include('session_type')
      response.body.should include('expires_in')
    end
    def associate_request_params
      { 'openid.ns' => OpenID::OPENID2_NS,
        'openid.mode' => 'associate',
        'openid.assoc_type' => 'HMAC-SHA1',
        'openid.session_type' => 'DH-SHA1',
        'openid.dh_consumer_public' => 'MgKzyEozjQH6uDumfyCGfDGWW2RM5QRfLi+Yu+h7SuW7l+jxk54/s9mWG+0ZR2J4LmhUO9Cw/sPqynxwqWGQLnxr0wYHxSsBIctUgxp67L/6qB+9GKM6URpv1mPkifv5k1M8hIJTQhzYXxHe+/7MM8BD47vBp0nihjaDr0XAe6w=' }
    end
  end

  describe "xrdsにアクセスした場合" do
    it "xrdsを返す" do
      get :index, :format => "xrds"
      response.should be_success
    end
  end

  # Takes the name of an account fixture for which to fake the request
  def fake_checkid_request(user)
    id_url = identifier(user)
    openid_params = checkid_request_params.merge('openid.identity' => id_url, 'openid.claimed_id' => id_url)
    @checkid_request = OpenIdRequest.create(:parameters => openid_params)
    session[:request_token] = @checkid_request.token
  end
end

describe ServerController, "#proceed" do
  before do
    @login_user = user_login

    @id_url = identifier(@login_user)

    controller.stub(:sso).and_return(true)
  end
  describe "ホワイトリストのアプリケーションの場合" do
    before do
      SkipEmbedded::InitialSettings['white_list'] = ["http://test.com/"]
      SkipEmbedded::InitialSettings['protocol'] = "http://"

      openid_params = checkid_request_params.merge('openid.identity' => @id_url, 'openid.claimed_id' => @id_url)
      @checkid_request = OpenIdRequest.create!(:parameters => openid_params)
      @request.session[:request_token] = @checkid_request.token
      controller.stub!(:convert_ax_props).and_return({"value.code"=>"111111",
                                                       "type.code"=>"http://axschema.org/namePerson/friendly",
                                                       "value.fullname"=>"一般ユーザ",
                                                       "type.fullname"=>"http://axschema.org/namePerson"})
    end

    it "認証後のURLにリダイレクトされる" do
      get :proceed
      response.should be_redirect
      response.body.should include(@checkid_request.parameters['openid.return_to'])
    end
    it "AXのパラメータが追加されること" do
      controller.should_receive(:add_ax).and_return(resp = mock("resp"))
      controller.should_receive(:render_response).with(resp)
      get :proceed
    end
  end

  describe "ホワイトリストのアプリケーションでない場合" do
    before do
      SkipEmbedded::InitialSettings['white_list'] = ["http://127.0.0.1/"]
      SkipEmbedded::InitialSettings['protocol'] = "http://"
      SkipEmbedded::InitialSettings['host_and_port'] = "localhost:3100"

      openid_params = checkid_request_params.merge('openid.identity' => @id_url, 'openid.claimed_id' => @id_url)
      @checkid_request = OpenIdRequest.create!(:parameters => openid_params)
      @request.session[:request_token] = @checkid_request.token

      get :proceed
    end

    it { response.should redirect_to(root_url) }
  end
end

describe ServerController, "#convert_ax_props" do
  before do
    @user = mock_model(User, :email => "email@example.com", :name => "full name", :code => "code")
  end
  it "正しい設定の場合、変換すること" do
    ax_props = [ ["email", "http://axschema.org/contact/email", "email"],
                 ["fullname", "http://axschema.org/namePerson", "name"],
                 ["code", "http://axschema.org/namePerson/friendly", "code"] ]
    valid_props = { "type.email" => "http://axschema.org/contact/email",
      "type.fullname" => "http://axschema.org/namePerson",
      "type.code" => "http://axschema.org/namePerson/friendly",
      "value.email"=> @user.email,
      "value.fullname"=> @user.name,
      "value.code" => @user.code }
    result = controller.send(:convert_ax_props, @user, ax_props)
    result.should == valid_props
  end
end
