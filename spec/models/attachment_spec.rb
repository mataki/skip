require 'spec_helper'

describe Attachment do
  fixtures :contents
  fixtures :chapters

  before(:each) do
    @uploaded_data = StringIO.new(File.read("spec/fixtures/data/at_small.png"))
    def @uploaded_data.original_filename; "at_small.png" end
    def @uploaded_data.content_type; "image/png" end

    @valid_attributes = {
      :uploaded_data => @uploaded_data,
      :user_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    Attachment.create!(@valid_attributes)
  end
end
