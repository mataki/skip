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

require File.dirname(__FILE__) + '/../spec_helper'

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
