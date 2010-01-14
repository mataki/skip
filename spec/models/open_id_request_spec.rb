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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe OpenIdRequest do
  before(:each) do
    @valid_attributes = {
      :token => "value for token",
      :parameters => checkid_request_params
    }
  end

  it "should create a new instance given valid attributes" do
    OpenIdRequest.create!(@valid_attributes)
  end
end

describe OpenIdRequest do

  before do
    @request = OpenIdRequest.create :parameters => checkid_request_params
  end

  def test_should_generate_token_on_create
    @request = OpenIdRequest.new :parameters => checkid_request_params
    assert_nil @request.token
    assert @request.save
    assert_not_nil @request.token
  end

  def test_should_reject_non_openid_parameters
    various_params = checkid_request_params.merge('test' => 1, 'foo' => 'bar')
    @request.parameters = various_params
    assert !@request.parameters.include?('test')
    assert !@request.parameters.include?('bar')
  end

end
