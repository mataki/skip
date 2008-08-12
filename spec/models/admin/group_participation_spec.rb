require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::GroupParticipation do
  before(:each) do
    @group_participation = Admin::GroupParticipation.new
  end

  it "should be valid" do
    @group_participation.should be_valid
  end
end
