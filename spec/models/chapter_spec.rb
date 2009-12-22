require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Chapter do
  before(:each) do
    @valid_attributes = {
      :data => "hogehoge"
    }
  end

  it "should create a new instance given valid attributes" do
    Chapter.create!(@valid_attributes)
  end
end
