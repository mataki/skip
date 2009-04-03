require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Ribbit do
  before(:each) do
    @valid_attributes = {
      :purpose_number => "value for purpose_number",
      :user => stub_model(User)
    }
  end

  it "should create a new instance given valid attributes" do
    Ribbit.create!(@valid_attributes)
  end
end
