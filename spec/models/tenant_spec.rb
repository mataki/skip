require 'spec_helper'

describe Tenant do
  before(:each) do
    @valid_attributes = {
      
    }
  end

  it "should create a new instance given valid attributes" do
    Tenant.create!(@valid_attributes)
  end
end
