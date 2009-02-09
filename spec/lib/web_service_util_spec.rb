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

describe WebServiceUtil, ".open_service" do
  before do
    INITIAL_SETTINGS["collaboration_apps"] = {}
    INITIAL_SETTINGS["collaboration_apps"]["app"] = {"url" => "http://testapp.host"}
    @base = "http://testapp.host/services/user_info"
  end
  it "get_jsonをパラメータからURLを作りだすこと" do
    WebServiceUtil.should_receive(:open_service_with_url).with(@base, { :id => "user", :key => "key" }, nil)
    WebServiceUtil.open_service "app", "user_info", { :id => "user", :key => "key" }
  end
end

describe WebServiceUtil, "open_service_with_url" do
  it "paramsがエンコードされてget_jsonに渡されること" do
    params = { :id => "user", :key => "ほげ%$# ふが" }
    query_str = params.map{|key,val| "#{key}=#{URI.encode(val)}" }.join('&')

    WebServiceUtil.should_receive(:get_json).with("url?#{query_str}", nil)
    WebServiceUtil.open_service_with_url "url", params
  end
end

describe WebServiceUtil, ".get_json" do
  before do
    @result = { "symbol" => "user", "type" => "entry"}
    @response = mock('response', :code => "200", :body => @result.to_json)
    @http = mock('http', :get => @response)
  end
  describe "レスポンスが正しく返ってくる場合" do
    before do
      Net::HTTP.stub!(:new).and_return(@http)
    end
    describe "httpの場合" do
      it "bodyがパースされて返されること" do
        WebServiceUtil.get_json("http://test.host/services/user_info?user_code=user").should == @result
      end
    end
    describe "httpsの場合" do
      before do
        @http.stub!(:use_ssl=)
        @http.stub!(:verify_mode=)
      end
      it "bodyがパースされて返されること" do
        WebServiceUtil.get_json("https://test.host/services/user_info?user_code=user").should == @result
      end
      it "httpがuse_ssl = trueで呼ばれること" do
        @http.should_receive(:use_ssl=).with(true)
        WebServiceUtil.get_json("https://test.host/services/user_info?user_code=user")
      end
      it "httpがverify_mode = OpenSSL::SSL::VERIFY_NONE で呼ばれること" do
        @http.should_receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
        WebServiceUtil.get_json("https://test.host/services/user_info?user_code=user")
      end
      describe "httpsでca_fileありの場合" do
        before do
          @ca_file = "#{RAILS_ROOT}/config/server.pem"
          @http.stub!(:ca_file=)
          @http.stub!(:verify_depth=)
        end
        it "bodyがパースされて返されること" do
          WebServiceUtil.get_json("https://test.host/services/user_info?user_code=user", @ca_file).should == @result
        end
        it "httpに ca_file が設定されること" do
          @http.should_receive(:ca_file=).with(@ca_file)
          WebServiceUtil.get_json("https://test.host/services/user_info?user_code=user", @ca_file)
        end
        it "httpに verify_depth が設定されること" do
          @http.should_receive(:verify_depth=).with(5)
          WebServiceUtil.get_json("https://test.host/services/user_info?user_code=user", @ca_file)
        end
      end
    end
  end
  describe "引数がnilの場合" do
    it "nilが返ること" do
      WebServiceUtil.get_json(nil).should be_nil
    end
    it "ログが出力されること" do
      ActiveRecord::Base.logger.should_receive(:error).with(/[WebServiceUtil Error] .*/)
      WebServiceUtil.get_json(nil).should be_nil
    end
  end
  describe "返ってくるものが正しくparseできない場合" do
    before do
      Net::HTTP.stub!(:new).and_return(@http)
      @response.stub!(:body).and_return("ぱーすにしっぱいする")
      @url = "http://test.host/services/user_info?user_code=user"
    end
    it "nilが返ること" do
      WebServiceUtil.get_json(@url).should be_nil
    end
    it "ログが出力されること" do
      ActiveRecord::Base.logger.should_receive(:error).with(/[WebServiceUtil Error] .*/)
      WebServiceUtil.get_json(@url).should be_nil
    end
  end
  describe "ホストの無いURLが渡された場合" do
    before do
      @url = "/services/user_info?user_code=user"
    end
    it "nilが返ること" do
      WebServiceUtil.get_json(@url).should be_nil
    end
    it "ログが出力されること" do
      ActiveRecord::Base.logger.should_receive(:error).with(/[WebServiceUtil Error] .*/)
      WebServiceUtil.get_json(@url).should be_nil
    end
  end
  describe "レスポンスが404の場合" do
    before do
      @url = "/services/user_info?user_code=user"
    end
    before do
      http = mock('http', :get => mock('response', :code => "404"))
      Net::HTTP.stub!(:new).and_return(http)
    end
    it "nilが返ること" do
      WebServiceUtil.get_json(@url).should be_nil
    end
    it "ログが出力されること" do
      ActiveRecord::Base.logger.should_receive(:error).with("[WebServiceUtil Error] Response code is 404 to access #{@url}")
      WebServiceUtil.get_json(@url).should be_nil
    end
  end
  describe "ホストが見つからない場合" do
    before do
      @url = "http://test1.host/services/user_info?user_code=user"
    end
    it "nilが返ること" do
      WebServiceUtil.get_json(@url).should be_nil
    end
    it "ログが出力されること" do
      ActiveRecord::Base.logger.should_receive(:error).with(/[WebServiceUtil Error]/)
      WebServiceUtil.get_json(@url).should be_nil
    end
  end
  # 証明書でSSL認証を行なう場合、以下のエラーが起こる。環境が無いのでコメントアウト
  # 自己証明書の場合 => hostname was not match with the server certificate
  # 証明書が正しくない => SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed
#   describe "証明書が正しくない場合場合" do
#     before do
#       @url = "https://www.openskip.org/services/user_info?user_code=user"
#       @ca_file = "#{RAILS_ROOT}/config/server.pem"
#     end
#     it "nilが返ること" do
#       WebServiceUtil.get_json(@url, @ca_file).should be_nil
#     end
#     it "ログが出力されること" do
#       ActiveRecord::Base.logger.should_receive(:error).with("[WebServiceUtil Error] XXXXX to access #{@url}")
#       WebServiceUtil.get_json(@url, @ca_file).should be_nil
#     end
#   end
end
