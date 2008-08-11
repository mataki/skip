require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BoardEntry do
  before(:each) do
    @board_entry = Admin::BoardEntry.new
  end

  it "should be valid" do
    @board_entry.should be_valid
  end
end
