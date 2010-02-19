require 'spec_helper'

describe Invitation do
  before(:each) do
    @valid_attributes = {
      :email => 'email@email.com',
      :body => 'body'
    }
  end

  it "should create a new instance given valid attributes" do
    Invitation.create!(@valid_attributes)
  end
end
